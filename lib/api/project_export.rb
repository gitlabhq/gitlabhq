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
          present user_project, with: Entities::ProjectExportStatus, current_user: current_user
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

          if user_project.export_file_exists?(current_user)
            if user_project.export_archive_exists?(current_user)
              present_carrierwave_file!(user_project.export_file(current_user))
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

          user_project.remove_export_for_user(current_user)

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
        params do
          optional :batched, type: Boolean, desc: 'Whether to export in batches'
        end
        post ':id/export_relations' do
          response = ::BulkImports::ExportService
            .new(portable: user_project, user: current_user, batched: params[:batched])
            .execute

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
          produces %w[application/octet-stream application/gzip application/json]
        end
        params do
          requires :relation, type: String, project_portable: true, desc: 'Project relation name'
          optional :batched, type: Boolean, desc: 'Whether to download in batches'
          optional :batch_number, type: Integer, desc: 'Batch number to download'

          all_or_none_of :batched, :batch_number
        end
        get ':id/export_relations/download' do
          export = user_project.bulk_import_exports.for_user_and_relation(current_user, params[:relation]).first

          break render_api_error!('Export not found', 404) unless export

          if params[:batched]
            batch = export.batches.find_by_batch_number(params[:batch_number])
            batch_file = batch&.upload&.export_file

            break render_api_error!('Export is not batched', 400) unless export.batched?
            break render_api_error!('Batch not found', 404) unless batch
            break render_api_error!('Batch file not found', 404) unless batch_file

            present_carrierwave_file!(batch_file)
          else
            file = export&.upload&.export_file

            break render_api_error!('Export is batched', 400) if export.batched?
            break render_api_error!('Export file not found', 404) unless file

            present_carrierwave_file!(file)
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
        params do
          optional :relation, type: String, desc: 'Project relation name'
        end
        get ':id/export_relations/status' do
          if params[:relation]
            export = user_project.bulk_import_exports.for_user_and_relation(current_user, params[:relation]).first

            break render_api_error!('Export not found', 404) unless export

            present export, with: Entities::BulkImports::ExportStatus
          else
            present user_project.bulk_import_exports.for_user(current_user), with: Entities::BulkImports::ExportStatus
          end
        end
      end
    end
  end
end
