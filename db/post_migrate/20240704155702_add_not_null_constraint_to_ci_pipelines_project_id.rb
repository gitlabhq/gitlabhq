# frozen_string_literal: true

class AddNotNullConstraintToCiPipelinesProjectId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.3'

  def up
    add_not_null_constraint :ci_pipelines, :project_id, validate: false
  end

  def down
    remove_not_null_constraint :ci_pipelines, :project_id
  end
end
