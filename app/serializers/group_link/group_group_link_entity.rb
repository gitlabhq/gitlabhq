# frozen_string_literal: true

module GroupLink
  class GroupGroupLinkEntity < GroupLink::GroupLinkEntity
    include RequestAwareEntity

    expose :source do |group_link|
      GroupEntity.represent(group_link.shared_from, only: [:id, :full_name, :web_url])
    end

    private

    def can_admin_group_link?(group_link, options)
      can?(current_user, admin_permission_name, group_link.shared_from)
    end

    def admin_permission_name
      :admin_group_member
    end
  end
end
