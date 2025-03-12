# frozen_string_literal: true

module API
  class GroupPlaceholderReassignments < ::API::Base
    helpers do
      def csv_upload_params
        declared_params(include_missing: false)
      end
    end

    before do
      authenticate!
      not_found! unless Feature.enabled?(:importer_user_mapping_reassignment_csv, current_user)
      forbidden! unless can?(current_user, :owner_access, user_group)
    end

    feature_category :importers

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Download the list of pending placeholder assignments for a group' do
        detail 'This feature was added in GitLab 17.10'
        success code: 200
      end
      get ':id/placeholder_reassignments' do
        csv_response = Import::SourceUsers::GenerateCsvService.new(user_group, current_user: current_user).execute

        if csv_response.success?
          content_type 'text/csv; charset=utf-8'
          header(
            "Content-Disposition",
            "attachment; filename=\"placeholder_reassignments_for_group_#{user_group.id}_#{Time.current.to_i}.csv\""
          )
          env['api.format'] = :csv
          csv_response.payload
        else
          unprocessable_entity!(csv_response.message)
        end
      end

      desc 'Workhorse authorization for the reassignment CSV file' do
        detail 'This feature was introduced in GitLab 17.10'
      end
      post ':id/placeholder_reassignments/authorize' do
        require_gitlab_workhorse!

        status 200
        content_type Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE

        ::Import::PlaceholderReassignmentsUploader.workhorse_authorize(
          has_length: false,
          maximum_size: Gitlab::CurrentSettings.max_attachment_size.megabytes
        )
      end

      params do
        requires :file,
          type: ::API::Validations::Types::WorkhorseFile,
          desc: 'The CSV file containing the reassignments',
          documentation: { type: 'file' }
      end
      post ':id/placeholder_reassignments' do
        require_gitlab_workhorse!

        unless csv_upload_params[:file].original_filename.ends_with?('.csv')
          unprocessable_entity!(s_('UserMapping|You must upload a CSV file with a .csv file extension.'))
        end

        uploader = UploadService.new(
          user_group,
          csv_upload_params[:file],
          ::Import::PlaceholderReassignmentsUploader
        ).execute

        result = Import::SourceUsers::BulkReassignFromCsvService.new(
          current_user,
          user_group,
          uploader.upload
        ).async_execute

        if result.success?
          { message: s_('UserMapping|The file is being processed and you will receive an email when completed.') }
        else
          unprocessable_entity!(result.message)
        end
      end
    end
  end
end
