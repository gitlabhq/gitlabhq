# frozen_string_literal: true

class AddStrategiesToOperationsFeatureFlagScopes < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :operations_feature_flag_scopes, :strategies, :jsonb, default: [{ name: "default", parameters: {} }] # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column(:operations_feature_flag_scopes, :strategies)
  end
end
