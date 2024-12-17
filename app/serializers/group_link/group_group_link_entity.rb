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
      can_admin_group_link?(group_link, options)
    end

    expose :can_remove do |group_link, options|
      can_admin_group_link?(group_link, options)
    end

    private

    def can_admin_group_link?(group_link, options)
      direct_member?(group_link, options) && can?(current_user, :admin_group_member, group_link.shared_from)
    end
  end
end
