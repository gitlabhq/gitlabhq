# frozen_string_literal: true

module BulkImports
  class ExportService
    # @param portable [Project|Group] A project or a group to export.
    # @param user [User] A user performing the export.
    # @param batched [Boolean] Whether to export the data in batches.
    def initialize(portable:, user:, batched: false)
      @portable = portable
      @current_user = user
      @batched = batched
    end

    def execute
      validate_user_permissions!

      FileTransfer.config_for(portable).portable_relations.each do |relation|
        RelationExportWorker.perform_async(current_user.id, portable.id, portable.class.name, relation, batched)
      end

      ServiceResponse.success
    rescue StandardError => e
      ServiceResponse.error(
        message: e.class,
        http_status: :unprocessable_entity
      )
    end

    private

    attr_reader :portable, :current_user, :batched

    def validate_user_permissions!
      ability = "admin_#{portable.to_ability_name}"

      current_user.can?(ability, portable) ||
        raise(::Gitlab::ImportExport::Error.permission_error(current_user, portable))
    end
  end
end
