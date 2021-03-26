# frozen_string_literal: true

class ValidateNotNullConstraintOnClusterTokenName < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    validate_not_null_constraint :cluster_agent_tokens, :name
  end

  def down
    # no-op
  end
end
