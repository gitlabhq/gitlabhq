# frozen_string_literal: true

class AddStrategiesToOperationsFeatureFlagScopes < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # rubocop:disable Migration/AddColumnWithDefault
    add_column_with_default :operations_feature_flag_scopes, :strategies, :jsonb, default: [{ name: "default", parameters: {} }]
    # rubocop:enable Migration/AddColumnWithDefault
  end

  def down
    remove_column(:operations_feature_flag_scopes, :strategies)
  end
end
