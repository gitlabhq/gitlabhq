module Projects
  module GroupLinks
    class CreateService < BaseService
      def execute(group)
        return false unless group

        project.project_group_links.create(
          group: group,
          group_access: params[:link_group_access],
          expires_at: params[:expires_at]
        )
      end
    end
  end
end
