# frozen_string_literal: true

module API
  class GroupExport < ::API::Base
    before do
      authorize! :admin_group, user_group
    end

    feature_category :importers
    urgency :low
    helpers Helpers::BulkImports::AuditHelpers

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups, requirements: { id: %r{[^/]+} } do
      desc 'Retrieve a group export download' do
        detail 'Retrieves the exported archive for a specified group.'
        tags %w[group_import_and_export]
        produces %w[application/octet-stream application/json]
        success code: 200
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' },
          { code: 503, message: 'Service unavailable' }
        ]
      end
      route_setting :authorization, permissions: :download_group_export, boundary_type: :group
      get ':id/export/download' do
        check_rate_limit! :group_download_export, scope: [current_user, user_group]

        if user_group.export_file_exists?(current_user)
          if user_group.export_archive_exists?(current_user)
            present_carrierwave_file!(user_group.export_file(current_user))
          else
            render_api_error!('The group export file is not available yet', 404)
          end
        else
          render_api_error!('404 Not found or has expired', 404)
        end
      end

      desc 'Create a group export' do
        detail 'Creates a group export for a specified group.'
        tags %w[group_import_and_export]
        success code: 202
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' },
          { code: 429, message: 'Too many requests' },
          { code: 503, message: 'Service unavailable' }
        ]
      end
      route_setting :authorization, permissions: :start_group_export, boundary_type: :group
      post ':id/export' do
        check_rate_limit! :group_export, scope: current_user

        export_service = ::Groups::ImportExport::ExportService.new(
          group: user_group,
          user: current_user,
          exported_by_admin: current_user.can_admin_all_resources?
        )

        if export_service.async_execute
          accepted!
        else
          render_api_error!(message: 'Group export could not be started.')
        end
      end

      resource do
        before do
          not_found! unless Gitlab::CurrentSettings.bulk_import_enabled?
        end

        desc 'Schedule a relations export for a group' do
          detail 'Schedules a relations export for a specified group.'
          tags %w[group_import_and_export]
          success code: 202
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' },
            { code: 503, message: 'Service unavailable' }
          ]
        end
        params do
          optional :batched, type: Boolean, desc: 'Whether to export in batches'
        end
        route_setting :authorization,
          permissions: :create_project_relation_export, boundary_type: :group
        post ':id/export_relations' do
          response = ::BulkImports::ExportService
            .new(portable: user_group, user: current_user, batched: params[:batched])
            .execute

          if response.success?
            log_direct_transfer_audit_event(
              ::Import::BulkImports::Audit::Events::EXPORT_INITIATED,
              'Direct Transfer relations export initiated',
              current_user,
              user_group
            )

            accepted!
          else
            render_api_error!(message: 'Group relations export could not be started.')
          end
        end

        desc 'Download a relations export for a group' do
          detail 'Downloads a group relations export file.'
          produces %w[application/octet-stream application/json]
          tags %w[group_import_and_export]
          success code: 200
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' },
            { code: 503, message: 'Service unavailable' }
          ]
        end
        params do
          requires :relation, type: String, desc: 'Group relation name'
          optional :batched, type: Boolean, desc: 'Whether to download in batches'
          optional :batch_number, type: Integer, desc: 'Batch number to download'

          all_or_none_of :batched, :batch_number
        end
        route_setting :authorization,
          permissions: :download_project_relation_export, boundary_type: :group
        get ':id/export_relations/download' do
          export = user_group.bulk_import_exports.for_user_and_relation(current_user, params[:relation])
            .for_offline_export(nil).first

          break render_api_error!('Export not found', 404) unless export

          if params[:batched]
            batch = export.batches.find_by_batch_number(params[:batch_number])
            batch_file = batch&.upload&.export_file

            break render_api_error!('Export is not batched', 400) unless export.batched?
            break render_api_error!('Batch not found', 404) unless batch
            break render_api_error!('Batch file not found', 404) unless batch_file

            log_direct_transfer_audit_event(
              ::Import::BulkImports::Audit::Events::EXPORT_BATCH_DOWNLOADED,
              'Direct Transfer relation export batch downloaded',
              current_user,
              user_group
            )

            present_carrierwave_file!(batch_file)
          else
            file = export&.upload&.export_file

            break render_api_error!('Export is batched', 400) if export.batched?
            break render_api_error!('Export file not found', 404) unless file

            log_direct_transfer_audit_event(
              ::Import::BulkImports::Audit::Events::EXPORT_DOWNLOADED,
              'Direct Transfer relation export downloaded',
              current_user,
              user_group
            )

            present_carrierwave_file!(file)
          end
        end

        desc 'Retrieve the status of an relations export for a group' do
          detail 'Retrieves the status of a relations export for a group.'
          is_array true
          tags %w[group_import_and_export]
          success code: 200, model: Entities::BulkImports::ExportStatus
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' },
            { code: 503, message: 'Service unavailable' }
          ]
        end
        params do
          optional :relation, type: String, desc: 'Group relation name'
        end
        route_setting :authorization,
          permissions: :read_project_relation_export, boundary_type: :group
        get ':id/export_relations/status' do
          if params[:relation]
            export = user_group.bulk_import_exports.for_user_and_relation(current_user, params[:relation])
              .for_offline_export(nil).first

            break render_api_error!('Export not found', 404) unless export

            present export, with: Entities::BulkImports::ExportStatus
          else
            present user_group.bulk_import_exports.for_user(current_user).for_offline_export(nil),
              with: Entities::BulkImports::ExportStatus
          end
        end
      end
    end
  end
end
