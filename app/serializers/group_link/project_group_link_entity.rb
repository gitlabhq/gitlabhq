# frozen_string_literal: true

module GroupLink
  class ProjectGroupLinkEntity < GroupLink::GroupLinkEntity
    include RequestAwareEntity

    expose :source, if: ->(group_link) { can_read_shared_group?(group_link) } do |group_link|
      ProjectEntity.represent(group_link.shared_from, only: [:id, :full_name])
    end

    expose :valid_roles do |_group_link|
      Gitlab::Access.options_with_owner
    end

    expose :can_update do |group_link, options|
      direct_member?(group_link, options) &&
        Ability.allowed?(current_user, :update_group_link, group_link)
    end

    expose :can_remove do |group_link, options|
      direct_member?(group_link, options) &&
        Ability.allowed?(current_user, :delete_group_link, group_link)
    end
  end
end
