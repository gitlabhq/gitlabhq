# frozen_string_literal: true

class AddProjectRelationExportsProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def up
    install_sharding_key_assignment_trigger(
      table: :project_relation_exports,
      sharding_key: :project_id,
      parent_table: :project_export_jobs,
      parent_sharding_key: :project_id,
      foreign_key: :project_export_job_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :project_relation_exports,
      sharding_key: :project_id,
      parent_table: :project_export_jobs,
      parent_sharding_key: :project_id,
      foreign_key: :project_export_job_id
    )
  end
end
