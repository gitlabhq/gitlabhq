# frozen_string_literal: true

module API
  module Entities
    class ProjectExportStatus < ProjectIdentity
      include ::API::Helpers::RelatedResourcesHelpers

      expose :export_status, documentation: {
        type: 'string', example: 'finished', values: %w[queued started finished failed]
      } do |project, options|
        project.export_status(options[:current_user])
      end
      expose :_links, if: ->(project, options) { project.export_status(options[:current_user]) == :finished } do
        expose :api_url, documentation: {
          type: 'string',
          example: 'https://gitlab.example.com/api/v4/projects/1/export/download'
        } do |project|
          expose_url(api_v4_projects_export_download_path(id: project.id))
        end

        expose :web_url, documentation: {
          type: 'string',
          example: 'https://gitlab.example.com/gitlab-org/gitlab-test/download_export'
        } do |project|
          Gitlab::Routing.url_helpers.download_export_project_url(project)
        end
      end
    end
  end
end
