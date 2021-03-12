# frozen_string_literal: true

# Entry point of the BulkImport feature.
# This service receives a Gitlab Instance connection params
# and a list of groups to be imported.
#
# Process topography:
#
#       sync      |   async
#                 |
#  User +--> P1 +----> Pn +---+
#                 |     ^     | Enqueue new job
#                 |     +-----+
#
# P1 (sync)
#
# - Create a BulkImport record
# - Create a BulkImport::Entity for each group to be imported
# - Enqueue a BulkImportWorker job (P2) to import the given groups (entities)
#
# Pn (async)
#
# - For each group to be imported (BulkImport::Entity.with_status(:created))
#   - Import the group data
#   - Create entities for each subgroup of the imported group
#   - Enqueue a BulkImportService job (Pn) to import the new entities (subgroups)
#
class BulkImportService
  attr_reader :current_user, :params, :credentials

  def initialize(current_user, params, credentials)
    @current_user = current_user
    @params = params
    @credentials = credentials
  end

  def execute
    bulk_import = create_bulk_import

    BulkImportWorker.perform_async(bulk_import.id)

    ServiceResponse.success(payload: bulk_import)
  rescue ActiveRecord::RecordInvalid => e
    ServiceResponse.error(
      message: e.message,
      http_status: :unprocessable_entity
    )
  end

  private

  def create_bulk_import
    BulkImport.transaction do
      bulk_import = BulkImport.create!(user: current_user, source_type: 'gitlab')
      bulk_import.create_configuration!(credentials.slice(:url, :access_token))

      params.each do |entity|
        BulkImports::Entity.create!(
          bulk_import: bulk_import,
          source_type: entity[:source_type],
          source_full_path: entity[:source_full_path],
          destination_name: entity[:destination_name],
          destination_namespace: entity[:destination_namespace]
        )
      end

      bulk_import
    end
  end
end
