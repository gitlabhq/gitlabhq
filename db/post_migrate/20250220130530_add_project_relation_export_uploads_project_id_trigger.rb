# frozen_string_literal: true

class AddProjectRelationExportUploadsProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def up
    install_sharding_key_assignment_trigger(
      table: :project_relation_export_uploads,
      sharding_key: :project_id,
      parent_table: :project_relation_exports,
      parent_sharding_key: :project_id,
      foreign_key: :project_relation_export_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :project_relation_export_uploads,
      sharding_key: :project_id,
      parent_table: :project_relation_exports,
      parent_sharding_key: :project_id,
      foreign_key: :project_relation_export_id
    )
  end
end
