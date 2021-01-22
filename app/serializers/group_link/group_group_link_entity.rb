# frozen_string_literal: true

module GroupLink
  class GroupGroupLinkEntity < GroupLink::GroupLinkEntity
    include RequestAwareEntity

    expose :can_update do |group_link|
      can_manage?(group_link)
    end

    expose :can_remove do |group_link|
      can_manage?(group_link)
    end

    private

    def current_user
      options[:current_user]
    end

    def can_manage?(group_link)
      can?(current_user, :admin_group_member, group_link.shared_group)
    end
  end
end
