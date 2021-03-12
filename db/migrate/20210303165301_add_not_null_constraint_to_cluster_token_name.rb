# frozen_string_literal: true

class AddNotNullConstraintToClusterTokenName < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # This will add the `NOT NULL` constraint WITHOUT validating it
    add_not_null_constraint :cluster_agent_tokens, :name, validate: false
  end

  def down
    remove_not_null_constraint :cluster_agent_tokens, :name
  end
end
