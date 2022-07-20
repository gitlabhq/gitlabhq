# frozen_string_literal: true

class AddLastFeatureFlagUpdatedAtToOperationsFeatureFlagsClients < Gitlab::Database::Migration[2.0]
  def change
    add_column :operations_feature_flags_clients, :last_feature_flag_updated_at, :datetime_with_timezone
  end
end
