# frozen_string_literal: true

class AddNamespaceStorageSizeLimitToApplicationSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  def up
    add_column_with_default :application_settings, :namespace_storage_size_limit, :bigint, default: 0 # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column :application_settings, :namespace_storage_size_limit
  end
end
