# frozen_string_literal: true

module GroupLink
  class ProjectGroupLinkEntity < GroupLink::GroupLinkEntity
    include RequestAwareEntity

    expose :source, if: ->(group_link) { can_read_shared_group?(group_link) } do |group_link|
      ProjectEntity.represent(group_link.shared_from, only: [:id, :full_name])
    end

    expose :valid_roles do |group_link|
      if can?(current_user, :manage_owners, group_link)
        Gitlab::Access.options_with_owner
      else
        Gitlab::Access.options
      end
    end

    expose :can_update do |group_link, options|
      direct_member?(group_link, options) &&
        can?(current_user, :admin_project_member, group_link.project) &&
        can?(current_user, :manage_group_link_with_owner_access, group_link)
    end

    expose :can_remove do |group_link, options|
      direct_member?(group_link, options) &&
        can?(current_user, :destroy_project_group_link, group_link)
    end
  end
end
