# frozen_string_literal: true

module Members
  # We allow the current user to see the invited private group when the current user is a member of the shared group to
  # allow better collaboration between the two groups even though the current user is not a member of the invited group.
  # We don't allow the current user to see the source of membership i.e. the group name, path, and other group info as
  # it's sensitive information if the current user is not an owner of the group or at least maintainer of the project.
  # This class deals with setting `is_source_accessible_to_current_user` which is used to hide or show the source of
  # memberships as per the above cases.
  class InvitedPrivateGroupAccessibilityAssigner
    include Gitlab::Allowable
    include Gitlab::Utils::StrongMemoize

    def initialize(members, source:, current_user:)
      @members = if members.is_a?(ActiveRecord::Base)
                   Array.wrap(members)
                 else
                   members.to_a
                 end

      @source = source
      @current_user = current_user
    end

    def execute
      # We don't need to calculate the access level of the current user in the invited groups if:
      #
      # 1. The current user can admin members then the user should be able to see the source of all memberships
      #    to enable management of group/project memberships.
      # 2. There are no members invited from a private group.
      return if can_admin_members? || private_invited_group_members.nil?

      private_invited_group_members.each do |member|
        member.is_source_accessible_to_current_user = authorized_groups.include?(member.source)
      end
    end

    private

    attr_reader :members, :source, :current_user

    def authorized_groups
      return [] if current_user.nil?

      private_invited_groups = private_invited_group_members.map(&:source).uniq
      Group.groups_user_can(private_invited_groups, current_user, :read_group)
    end
    strong_memoize_attr(:authorized_groups)

    def private_invited_group_members
      members.select do |member|
        # The user can see those members where:
        # - The source is public.
        # - The member is direct or inherited. ProjectMember type is always direct.
        member.is_a?(GroupMember) &&
          member.source.visibility_level != Gitlab::VisibilityLevel::PUBLIC &&
          member.source_id != source.id && # Exclude direct member
          source_traversal_ids.exclude?(member.source_id) # Exclude inherited member
      end
    end
    strong_memoize_attr(:private_invited_group_members)

    def source_traversal_ids
      if source.is_a?(Project)
        source.namespace.traversal_ids
      else
        source.traversal_ids
      end
    end
    strong_memoize_attr(:source_traversal_ids)

    def can_admin_members?
      return can?(current_user, :admin_project_member, source) if source.is_a?(Project)

      can?(current_user, :admin_group_member, source)
    end
  end
end
