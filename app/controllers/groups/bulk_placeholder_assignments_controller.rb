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

      unless file_is_valid?(file_params[:file])
        respond_to do |format|
          format.json do
            render json: { message: s_('UserMapping|You must upload a CSV file with a .csv file extension.') },
              status: :unprocessable_entity
          end
        end
        return
      end

      respond_to do |format|
        format.json do
          render json: {
            message: s_('UserMapping|The file is being processed and you will receive an email when completed.')
          }
        end
      end
    end

    private

    def file_params
      params.permit(:file)
    end

    def uploader_class
      FileUploader
    end

    def file_extension_allowlist
      PERMITTED_FILE_EXTENSIONS
    end

    def maximum_size
      Gitlab::CurrentSettings.max_attachment_size.megabytes
    end
  end
end
