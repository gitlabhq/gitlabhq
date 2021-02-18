# frozen_string_literal: true

module GroupLink
  class ProjectGroupLinkEntity < GroupLink::GroupLinkEntity
    include RequestAwareEntity
    include Projects::ProjectMembersHelper

    expose :can_update do |group_link|
      can_manage_project_members?(group_link.project)
    end

    expose :can_remove do |group_link|
      can_manage_project_members?(group_link.project)
    end

    private

    def current_user
      options[:current_user]
    end
  end
end
