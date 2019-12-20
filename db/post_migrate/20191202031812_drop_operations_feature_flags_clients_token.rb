# frozen_string_literal: true

class DropOperationsFeatureFlagsClientsToken < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # Ignored in 12.5 - https://gitlab.com/gitlab-org/gitlab/merge_requests/18923
    remove_column :operations_feature_flags_clients, :token
  end

  def down
    unless column_exists?(:operations_feature_flags_clients, :token)
      add_column :operations_feature_flags_clients, :token, :string # rubocop:disable Migration/AddLimitToStringColumns
    end

    add_concurrent_index :operations_feature_flags_clients, [:project_id, :token], unique: true,
      name: 'index_operations_feature_flags_clients_on_project_id_and_token'
  end
end
