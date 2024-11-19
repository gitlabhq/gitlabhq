# frozen_string_literal: true

class DeleteImportExportUploadsWithoutProjectIdOrGroupId < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    define_batchable_model('import_export_uploads').each_batch(of: 10_000) do |batch|
      batch.where('project_id IS NULL AND group_id IS NULL').delete_all
    end
  end

  def down
    # no-op
  end
end
