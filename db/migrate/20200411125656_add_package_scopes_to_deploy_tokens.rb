# frozen_string_literal: true

class AddPackageScopesToDeployTokens < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:deploy_tokens, :read_package_registry, :boolean, default: false, allow_null: false) # rubocop:disable Migration/AddColumnWithDefault
    add_column_with_default(:deploy_tokens, :write_package_registry, :boolean, default: false, allow_null: false) # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column(:deploy_tokens, :read_package_registry)
    remove_column(:deploy_tokens, :write_package_registry)
  end
end
