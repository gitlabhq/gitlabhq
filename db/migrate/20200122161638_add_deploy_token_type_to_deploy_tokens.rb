# frozen_string_literal: true

class AddDeployTokenTypeToDeployTokens < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_column_with_default :deploy_tokens, :deploy_token_type, :integer, default: 2, limit: 2, allow_null: false # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column :deploy_tokens, :deploy_token_type
  end
end
