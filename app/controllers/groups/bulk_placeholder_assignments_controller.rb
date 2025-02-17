# frozen_string_literal: true

module Groups
  class BulkPlaceholderAssignmentsController < Groups::ApplicationController
    include WorkhorseAuthorization

    PERMITTED_FILE_EXTENSIONS = %w[csv].freeze

    before_action :authorize_owner_access!

    feature_category :importers

    def show
      return render_404 unless Feature.enabled?(:importer_user_mapping_reassignment_csv, current_user)

      csv_response = Import::SourceUsers::GenerateCsvService.new(group, current_user: current_user).execute

      if csv_response.success?
        send_data(
          csv_response.payload,
          filename: "bulk_reassignments_for_namespace_#{group.id}_#{Time.current.to_i}.csv",
          type: 'text/csv; charset=utf-8'
        )
      else
        redirect_back_or_default(options: { alert: csv_response.message })
      end
    end

    def create
      return render_404 unless Feature.enabled?(:importer_user_mapping_reassignment_csv, current_user)

      unless file_type_is_valid?(file_params[:file])
        render_unprocessable_entity(s_('UserMapping|You must upload a CSV file with a .csv file extension.'))
        return
      end

      uploader = UploadService.new(
        group,
        file_params[:file],
        uploader_class
      ).execute

      result = Import::SourceUsers::BulkReassignFromCsvService.new(
        current_user,
        group,
        uploader.upload
      ).async_execute

      if result.success?
        respond_to do |format|
          format.json do
            render json: {
              message: s_('UserMapping|The file is being processed and you will receive an email when completed.')
            }
          end
        end
      else
        render_unprocessable_entity(result.message)
      end
    end

    private

    alias_method :file_type_is_valid?, :file_is_valid?

    def file_params
      params.permit(:file)
    end

    def uploader_class
      ::Import::PlaceholderReassignmentsUploader
    end

    def file_extension_allowlist
      PERMITTED_FILE_EXTENSIONS
    end

    def maximum_size
      Gitlab::CurrentSettings.max_attachment_size.megabytes
    end

    def render_unprocessable_entity(message)
      respond_to do |format|
        format.json do
          render json: { message: message }, status: :unprocessable_entity
        end
      end
    end
  end
end
