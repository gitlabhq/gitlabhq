# frozen_string_literal: true

module API
  class ProjectExport < ::API::Base
    helpers Helpers::RateLimiter

    feature_category :importers

    before do
      not_found! unless Gitlab::CurrentSettings.project_export_enabled?
      authorize_admin_project
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: { id: %r{[^/]+} } do
      desc 'Get export status' do
        detail 'This feature was introduced in GitLab 10.6.'
        success Entities::ProjectExportStatus
      end
      get ':id/export' do
        present user_project, with: Entities::ProjectExportStatus
      end

      desc 'Download export' do
        detail 'This feature was introduced in GitLab 10.6.'
      end
      get ':id/export/download' do
        check_rate_limit! :project_download_export, [current_user, user_project]

        if user_project.export_file_exists?
          if user_project.export_archive_exists?
            present_carrierwave_file!(user_project.export_file)
          else
            render_api_error!('The project export file is not available yet', 404)
          end
        else
          render_api_error!('404 Not found or has expired', 404)
        end
      end

      desc 'Start export' do
        detail 'This feature was introduced in GitLab 10.6.'
      end
      params do
        optional :description, type: String, desc: 'Override the project description'
        optional :upload, type: Hash do
          optional :url, type: String, desc: 'The URL to upload the project'
          optional :http_method, type: String, default: 'PUT', desc: 'HTTP method to upload the exported project'
        end
      end
      post ':id/export' do
        check_rate_limit! :project_export, [current_user]

        user_project.remove_exports

        project_export_params = declared_params(include_missing: false)
        after_export_params = project_export_params.delete(:upload) || {}

        export_strategy = if after_export_params[:url].present?
                            params = after_export_params.slice(:url, :http_method).symbolize_keys

                            Gitlab::ImportExport::AfterExportStrategies::WebUploadStrategy.new(**params)
                          end

        if export_strategy&.invalid?
          render_validation_error!(export_strategy)
        else
          user_project.add_export_job(current_user: current_user,
                                      after_export_strategy: export_strategy,
                                      params: project_export_params)
        end

        accepted!
      end
    end
  end
end
