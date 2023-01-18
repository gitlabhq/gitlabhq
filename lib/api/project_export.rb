# frozen_string_literal: true

module API
  class ProjectExport < ::API::Base
    feature_category :importers
    urgency :low

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: { id: %r{[^/]+} } do
      resource do
        before do
          not_found! unless Gitlab::CurrentSettings.project_export_enabled?

          authorize_admin_project
        end

        desc 'Get export status' do
          detail 'This feature was introduced in GitLab 10.6.'
          success code: 200, model: Entities::ProjectExportStatus
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' },
            { code: 503, message: 'Service unavailable' }
          ]
          tags ['project_export']
        end
        get ':id/export' do
          present user_project, with: Entities::ProjectExportStatus
        end

        desc 'Download export' do
          detail 'This feature was introduced in GitLab 10.6.'
          success code: 200
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' },
            { code: 503, message: 'Service unavailable' }
          ]
          tags ['project_export']
          produces %w[application/octet-stream application/json]
        end
        get ':id/export/download' do
          check_rate_limit! :project_download_export, scope: [current_user, user_project.namespace]

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
          success code: 202
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' },
            { code: 429, message: 'Too many requests' },
            { code: 503, message: 'Service unavailable' }
          ]
          tags ['project_export']
        end
        params do
          optional :description, type: String, desc: 'Override the project description'
          optional :upload, type: Hash do
            optional :url, type: String, desc: 'The URL to upload the project'
            optional :http_method, type: String, default: 'PUT', values: %w[PUT POST],
                                   desc: 'HTTP method to upload the exported project'
          end
        end
        post ':id/export' do
          check_rate_limit! :project_export, scope: current_user

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
            begin
              user_project.add_export_job(current_user: current_user,
                                          after_export_strategy: export_strategy,
                                          params: project_export_params)
            rescue Project::ExportLimitExceeded => e
              render_api_error!(e.message, 400)
            end
          end

          accepted!
        end
      end

      resource do
        before do
          not_found! unless Gitlab::CurrentSettings.bulk_import_enabled?

          authorize_admin_project
        end

        desc 'Start relations export' do
          detail 'This feature was introduced in GitLab 14.4'
          success code: 202
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' },
            { code: 503, message: 'Service unavailable' }
          ]
          tags ['project_export']
        end
        post ':id/export_relations' do
          response = ::BulkImports::ExportService.new(portable: user_project, user: current_user).execute

          if response.success?
            accepted!
          else
            render_api_error!('Project relations export could not be started.', 500)
          end
        end

        desc 'Download relations export' do
          detail 'This feature was introduced in GitLab 14.4'
          success code: 200
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' },
            { code: 500, message: 'Internal Server Error' },
            { code: 503, message: 'Service unavailable' }
          ]
          tags ['project_export']
          produces %w[application/octet-stream application/json]
        end
        params do
          requires :relation,
                   type: String,
                   project_portable: true,
                   desc: 'Project relation name'
        end
        get ':id/export_relations/download' do
          export = user_project.bulk_import_exports.find_by_relation(params[:relation])
          file = export&.upload&.export_file

          if file
            present_carrierwave_file!(file)
          else
            render_api_error!('404 Not found', 404)
          end
        end

        desc 'Relations export status' do
          detail 'This feature was introduced in GitLab 14.4'
          is_array true
          success code: 200, model: Entities::BulkImports::ExportStatus
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' },
            { code: 503, message: 'Service unavailable' }
          ]
          tags ['project_export']
        end
        get ':id/export_relations/status' do
          present user_project.bulk_import_exports, with: Entities::BulkImports::ExportStatus
        end
      end
    end
  end
end
