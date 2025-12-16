# frozen_string_literal: true

class AddNotNullConstraintOnPiereuuShardingKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    add_not_null_constraint(:project_import_export_relation_export_upload_uploads, :project_id)
  end

  def down
    remove_not_null_constraint(:project_import_export_relation_export_upload_uploads, :project_id)
  end
end
