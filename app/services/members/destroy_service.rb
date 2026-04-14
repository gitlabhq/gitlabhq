# frozen_string_literal: true

module Members
  class DestroyService < Members::BaseService
    include Gitlab::ExclusiveLeaseHelpers

    # member: Member to destroy.
    # options: Configuration for this service. Can be any of the following:
    #   - skip_authorization: Whether to skip authorization checks.
    #   - skip_subresources: Whether to skip deleting subresources.
    #   - unassign_issuables: Whether to unassign issuables from the member.
    #   - destroy_bot: Whether this is a bot member destruction.
    #   - skip_saml_identity: Whether to skip SAML identity deletion.
    #   - ip_address: IP address of the request, used for audit events.
    def initialize(member, current_user: nil, **options)
      @member = member
      @current_user = current_user
      @skip_authorization = options[:skip_authorization]
      @skip_subresources = options[:skip_subresources]
      @unassign_issuables = options[:unassign_issuables]
      @destroy_bot = options[:destroy_bot]
      @skip_saml_identity = options[:skip_saml_identity]
      @ip_address = options[:ip_address]
    end

    def execute
      unless skip_authorization
        raise Gitlab::Access::AccessDeniedError unless authorized?

        raise Gitlab::Access::AccessDeniedError if destroying_member_with_owner_access_level? &&
          cannot_revoke_owner_responsibilities_from_member_in_project?(member)
      end

      if a_group_owner?
        process_destroy_of_group_owner_member
      else
        destroy_member
        destroy_data_related_to_member
      end

      enqueue_jobs_that_needs_to_be_run_only_once_per_hierarchy
      publish_events_once

      member
    end

    # We use this to mark recursive calls made to this service from within the same service.
    # We do this so as to help us run some tasks that needs to be run only once per hierarchy, and not recursively.
    def mark_as_recursive_call
      @recursive_call = true
    end

    private

    attr_reader :member, :skip_authorization, :skip_subresources, :unassign_issuables,
      :destroy_bot, :skip_saml_identity, :ip_address

    def publish_events_once
      return if recursive_call?

      publish_destroyed_event
    end

    # These actions need to be executed only once per hierarchy because the underlying services
    # apply these actions to the entire hierarchy anyway, so there is no need to execute them recursively.
    def enqueue_jobs_that_needs_to_be_run_only_once_per_hierarchy
      return if recursive_call?

      enqueue_cleanup_jobs_once_per_hierarchy
    end

    def enqueue_cleanup_jobs_once_per_hierarchy
      enqueue_delete_todos(member)
      enqueue_unassign_issuables if unassign_issuables
    end

    def recursive_call?
      @recursive_call == true
    end

    def process_destroy_of_group_owner_member
      # Deleting 2 different group owners via the API in quick succession could lead to
      # wrong results for the `last_owner?` check due to race conditions. To prevent this
      # we wrap both the last_owner? check and the deletes of owners within a lock.
      last_group_owner = true

      in_lock("delete_members:#{member.source.class}:#{member.source.id}", sleep_sec: 0.1.seconds) do
        # Explicitly bypass caching to ensure we're checking against the latest list of owners.
        break if ApplicationRecord.uncached { member.source.last_owner?(member.user) }

        last_group_owner = false
        destroy_member
      end

      # deletion of related data does not have to be within the lock.
      destroy_data_related_to_member unless last_group_owner
    end

    def destroy_member
      member.destroy
    end

    def destroy_data_related_to_member
      member.user&.invalidate_cache_counts
      delete_member_associations
    end

    def a_group_owner?
      member.is_a?(GroupMember) && member.owner?
    end

    def delete_member_associations
      if member.request? && member.user != current_user
        Members::AccessDeniedMailer.with(member: member).email.deliver_later # rubocop:disable CodeReuse/ActiveRecord -- false positive
      end

      delete_subresources unless skip_subresources
      delete_project_invitations_by unless skip_subresources
      resolve_access_request_todos(member)

      after_execute(member: member, skip_saml_identity: skip_saml_identity)
    end

    def authorized?
      return can_destroy_bot_member? if destroy_bot

      return can_destroy_member_access_request? || can_withdraw_member_access_request? if member.request?

      can_destroy_member?
    end

    def delete_subresources
      return unless member.is_a?(GroupMember) && member.user && member.group

      delete_project_members
      delete_subgroup_members
      delete_invited_members
    end

    def delete_project_members
      groups = member.group.self_and_descendants

      destroy_project_members(ProjectMember.in_namespaces(groups).with_user(member.user))
    end

    def delete_subgroup_members
      groups = member.group.descendants

      destroy_group_members(GroupMember.of_groups(groups).with_user(member.user))
    end

    def delete_invited_members
      groups = member.group.self_and_descendants

      destroy_group_members(GroupMember.of_groups(groups).not_accepted_invitations_by_user(member.user))

      destroy_project_members(ProjectMember.in_namespaces(groups).not_accepted_invitations_by_user(member.user))
    end

    def destroy_project_members(members)
      members.each do |project_member|
        service = self.class.new(project_member, current_user: current_user,
          skip_authorization: skip_authorization, ip_address: ip_address)
        service.mark_as_recursive_call
        service.execute
      end
    end

    def destroy_group_members(members)
      members.each do |group_member|
        service = self.class.new(group_member, current_user: current_user,
          skip_authorization: skip_authorization, skip_subresources: true, ip_address: ip_address)
        service.mark_as_recursive_call
        service.execute
      end
    end

    def delete_project_invitations_by
      return unless member.is_a?(ProjectMember) && member.user && member.project

      members_to_delete = member.project.members.not_accepted_invitations_by_user(member.user)
      destroy_project_members(members_to_delete)
    end

    def can_destroy_member?
      can?(current_user, destroy_member_permission, member)
    end

    def can_destroy_bot_member?
      can?(current_user, destroy_bot_member_permission, member)
    end

    def can_destroy_member_access_request?
      can?(current_user, :admin_member_access_request, member.source)
    end

    def can_withdraw_member_access_request?
      can?(current_user, :withdraw_member_access_request, member)
    end

    def destroying_member_with_owner_access_level?
      member.owner?
    end

    def destroy_member_permission
      case member
      when GroupMember
        destroy_group_member_permission
      when ProjectMember
        :destroy_project_member
      else
        raise "Unknown member type: #{member}!"
      end
    end

    # overridden in EE::Members::DestroyService
    def destroy_group_member_permission
      :destroy_group_member
    end

    def destroy_bot_member_permission
      raise "Unsupported bot member type: #{member}" unless member.is_a?(ProjectMember)

      :destroy_project_bot_member
    end

    def enqueue_unassign_issuables
      source_type = member.is_a?(GroupMember) ? 'Group' : 'Project'
      current_user_id = current_user.id
      member_user_id = member.user_id
      member_source_id = member.source_id

      member.run_after_commit_or_now do
        MembersDestroyer::UnassignIssuablesWorker.perform_async(
          member_user_id,
          member_source_id,
          source_type,
          current_user_id
        )
      end
    end

    def publish_destroyed_event
      root_namespace_id = member.source.root_ancestor.id
      member_source_id = member.source_id
      member_source_type = member.source_type
      member_user_id = member.user_id

      member.run_after_commit_or_now do
        Gitlab::EventStore.publish(
          Members::DestroyedEvent.new(
            data: {
              root_namespace_id: root_namespace_id,
              source_id: member_source_id,
              source_type: member_source_type,
              user_id: member_user_id
            }
          )
        )
      end
    end
  end
end

Members::DestroyService.prepend_mod_with('Members::DestroyService')
