# frozen_string_literal: true

module API
  module Entities
    class ProjectExportStatus < ProjectIdentity
      include ::API::Helpers::RelatedResourcesHelpers

      expose :export_status
      expose :_links, if: lambda { |project, _options| project.export_status == :finished } do
        expose :api_url do |project|
          expose_url(api_v4_projects_export_download_path(id: project.id))
        end

        expose :web_url do |project|
          Gitlab::Routing.url_helpers.download_export_project_url(project)
        end
      end
    end
  end
end
