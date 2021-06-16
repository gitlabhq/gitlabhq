# frozen_string_literal: true

module API
  class GroupExport < ::API::Base
    helpers Helpers::RateLimiter

    before do
      not_found! unless Feature.enabled?(:group_import_export, user_group, default_enabled: true)

      authorize! :admin_group, user_group
    end

    feature_category :importers

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups, requirements: { id: %r{[^/]+} } do
      desc 'Download export' do
        detail 'This feature was introduced in GitLab 12.5.'
      end
      get ':id/export/download' do
        check_rate_limit! :group_download_export, [current_user, user_group]

        if user_group.export_file_exists?
          if user_group.export_archive_exists?
            present_carrierwave_file!(user_group.export_file)
          else
            render_api_error!('The group export file is not available yet', 404)
          end
        else
          render_api_error!('404 Not found or has expired', 404)
        end
      end

      desc 'Start export' do
        detail 'This feature was introduced in GitLab 12.5.'
      end
      post ':id/export' do
        check_rate_limit! :group_export, [current_user]

        export_service = ::Groups::ImportExport::ExportService.new(group: user_group, user: current_user)

        if export_service.async_execute
          accepted!
        else
          render_api_error!(message: 'Group export could not be started.')
        end
      end

      desc 'Start relations export' do
        detail 'This feature was introduced in GitLab 13.12'
      end
      post ':id/export_relations' do
        response = ::BulkImports::ExportService.new(portable: user_group, user: current_user).execute

        if response.success?
          accepted!
        else
          render_api_error!(message: 'Group relations export could not be started.')
        end
      end

      desc 'Download relations export' do
        detail 'This feature was introduced in GitLab 13.12'
      end
      params do
        requires :relation, type: String, desc: 'Group relation name'
      end
      get ':id/export_relations/download' do
        export = user_group.bulk_import_exports.find_by_relation(params[:relation])
        file = export&.upload&.export_file

        if file
          present_carrierwave_file!(file)
        else
          render_api_error!('404 Not found', 404)
        end
      end

      desc 'Relations export status' do
        detail 'This feature was introduced in GitLab 13.12'
      end
      get ':id/export_relations/status' do
        present user_group.bulk_import_exports, with: Entities::BulkImports::ExportStatus
      end
    end
  end
end
