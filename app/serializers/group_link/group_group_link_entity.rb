# frozen_string_literal: true

module GroupLink
  class GroupGroupLinkEntity < GroupLink::GroupLinkEntity
    include RequestAwareEntity

    expose :source, if: ->(group_link) { can_read_shared_group?(group_link) } do |group_link|
      GroupEntity.represent(group_link.shared_from, only: [:id, :full_name, :web_url])
    end

    expose :valid_roles do |group_link|
      group_link.class.access_options
    end

    expose :can_update do |group_link, options|
      direct_member?(group_link, options) && Ability.allowed?(current_user, :update_group_link, group_link.shared_from)
    end

    expose :can_remove do |group_link, options|
      direct_member?(group_link, options) && Ability.allowed?(current_user, :delete_group_link, group_link.shared_from)
    end
  end
end
