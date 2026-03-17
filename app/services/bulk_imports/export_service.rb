# frozen_string_literal: true

module BulkImports
  class ExportService
    # @param portable [Project|Group] A project or a group to export.
    # @param user [User] A user performing the export.
    # @param batched [Boolean] Whether to export the data in batches.
    # @param offline_export_id [Integer] ID of offline transfer to which export is related
    def initialize(portable:, user:, batched: false, offline_export_id: nil)
      @portable = portable
      @current_user = user
      @batched = batched
      @offline_export_id = offline_export_id
    end

    def execute
      validate_user_permissions!

      FileTransfer.config_for(portable).portable_relations.each do |relation|
        RelationExportWorker.perform_async(
          current_user.id,
          portable.id,
          portable.class.name,
          relation,
          batched,
          { 'offline_export_id' => offline_export_id }
        )
      end

      ServiceResponse.success
    rescue StandardError => e
      ServiceResponse.error(
        message: e.message,
        http_status: :unprocessable_entity
      )
    end

    private

    attr_reader :portable, :current_user, :batched, :offline_export_id

    def validate_user_permissions!
      ability = "admin_#{portable.to_ability_name}"

      current_user.can?(ability, portable) ||
        raise(::Gitlab::ImportExport::Error.permission_error(current_user, portable))
    end
  end
end
