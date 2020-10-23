# frozen_string_literal: true

class BulkImportService
  attr_reader :current_user, :params, :credentials

  def initialize(current_user, params, credentials)
    @current_user = current_user
    @params = params
    @credentials = credentials
  end

  def execute
    bulk_import = create_bulk_import
    bulk_import.start!

    BulkImportWorker.perform_async(bulk_import.id)
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
