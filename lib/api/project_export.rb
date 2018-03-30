module API
  class ProjectExport < Grape::API
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
        path = user_project.export_project_path

        render_api_error!('404 Not found or has expired', 404) unless path

        present_disk_file!(path, File.basename(path), 'application/gzip')
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
        project_export_params = declared_params(include_missing: false)
        after_export_params = project_export_params.delete(:upload) || {}

        export_strategy = if after_export_params[:url].present?
                            params = after_export_params.slice(:url, :http_method).symbolize_keys

                            Gitlab::ImportExport::AfterExportStrategies::WebUploadStrategy.new(params)
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
