# frozen_string_literal: true

class AddNotNullConstraintToPushRulesProjectId < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!

  def up
    add_not_null_constraint :push_rules, :project_id, validate: false
  end

  def down
    remove_not_null_constraint :push_rules, :project_id
  end
end
