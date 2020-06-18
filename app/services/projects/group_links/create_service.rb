# frozen_string_literal: true

module Projects
  module GroupLinks
    class CreateService < BaseService
      def execute(group)
        return error('Not Found', 404) unless group && can?(current_user, :read_namespace, group)

        link = project.project_group_links.new(
          group: group,
          group_access: params[:link_group_access],
          expires_at: params[:expires_at]
        )

        if link.save
          group.refresh_members_authorized_projects
          success(link: link)
        else
          error(link.errors.full_messages.to_sentence, 409)
        end
      end
    end
  end
end

Projects::GroupLinks::CreateService.prepend_if_ee('EE::Projects::GroupLinks::CreateService')
