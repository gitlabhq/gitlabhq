# frozen_string_literal: true

class ChangeOperationsFeatureFlagsClientsTokenNotNull < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    change_column_null :operations_feature_flags_clients, :token, true
  end
end
