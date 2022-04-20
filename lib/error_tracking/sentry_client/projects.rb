# frozen_string_literal: true

module ErrorTracking
  class SentryClient
    module Projects
      def projects
        projects = get_projects

        handle_mapping_exceptions do
          map_to_projects(projects)
        end
      end

      private

      def get_projects
        http_get(api_urls.projects_url)[:body]
      end

      def map_to_projects(projects)
        projects.map { map_to_project(_1) }
      end

      def map_to_project(project)
        organization = project.fetch('organization')

        Gitlab::ErrorTracking::Project.new(
          id: project.fetch('id', nil),
          name: project.fetch('name'),
          slug: project.fetch('slug'),
          status: project['status'],
          organization_name: organization.fetch('name'),
          organization_id: organization.fetch('id', nil),
          organization_slug: organization.fetch('slug')
        )
      end
    end
  end
end
