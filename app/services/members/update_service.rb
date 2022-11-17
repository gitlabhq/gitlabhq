# frozen_string_literal: true

module Members
  class UpdateService < Members::BaseService
    # @param members [Member, Array<Member>]
    # returns the updated member(s)
    def execute(members, permission: :update)
      members = Array.wrap(members)

      old_access_level_expiry_map = members.to_h do |member|
        [member.id, { human_access: member.human_access, expires_at: member.expires_at }]
      end

      if Feature.enabled?(:bulk_update_membership_roles, current_user)
        multiple_members_update(members, permission, old_access_level_expiry_map)
      else
        single_member_update(members.first, permission, old_access_level_expiry_map)
      end

      prepare_response(members)
    end

    private

    def single_member_update(member, permission, old_access_level_expiry_map)
      raise Gitlab::Access::AccessDeniedError unless has_update_permissions?(member, permission)

      member.attributes = params
      return success(member: member) unless member.changed?

      post_update(member, permission, old_access_level_expiry_map) if member.save
    end

    def multiple_members_update(members, permission, old_access_level_expiry_map)
      begin
        updated_members =
          Member.transaction do
            # Using `next` with `filter_map` avoids the `post_update` call for the member that resulted in no change
            members.filter_map do |member|
              raise Gitlab::Access::AccessDeniedError unless has_update_permissions?(member, permission)

              member.attributes = params
              next unless member.changed?

              member.save!
              member
            end
          end
      rescue ActiveRecord::RecordInvalid
        return
      end

      updated_members.each { |member| post_update(member, permission, old_access_level_expiry_map) }
    end

    def post_update(member, permission, old_access_level_expiry_map)
      old_access_level = old_access_level_expiry_map[member.id][:human_access]
      old_expiry = old_access_level_expiry_map[member.id][:expires_at]

      after_execute(action: permission, old_access_level: old_access_level, old_expiry: old_expiry, member: member)
      enqueue_delete_todos(member) if downgrading_to_guest? # Deletes only confidential issues todos for guests
    end

    def prepare_response(members)
      errored_member = members.detect { |member| member.errors.any? }
      if errored_member.present?
        return error(errored_member.errors.full_messages.to_sentence, pass_back: { member: errored_member })
      end

      # TODO: Remove the :member key when removing the bulk_update_membership_roles FF and update where it's used.
      # https://gitlab.com/gitlab-org/gitlab/-/issues/373257
      if members.one?
        success(member: members.first)
      else
        success(members: members)
      end
    end

    def has_update_permissions?(member, permission)
      can?(current_user, action_member_permission(permission, member), member) &&
        !prevent_upgrade_to_owner?(member) &&
        !prevent_downgrade_from_owner?(member)
    end

    def downgrading_to_guest?
      params[:access_level] == Gitlab::Access::GUEST
    end

    def upgrading_to_owner?
      params[:access_level] == Gitlab::Access::OWNER
    end

    def downgrading_from_owner?(member)
      member.owner?
    end

    def prevent_upgrade_to_owner?(member)
      upgrading_to_owner? && cannot_assign_owner_responsibilities_to_member_in_project?(member)
    end

    def prevent_downgrade_from_owner?(member)
      downgrading_from_owner?(member) && cannot_revoke_owner_responsibilities_from_member_in_project?(member)
    end
  end
end

Members::UpdateService.prepend_mod_with('Members::UpdateService')
