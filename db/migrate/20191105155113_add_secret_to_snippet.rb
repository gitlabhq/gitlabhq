# frozen_string_literal: true

class AddSecretToSnippet < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless column_exists?(:snippets, :secret)
      add_column_with_default :snippets, :secret, :boolean, default: false # rubocop:disable Migration/AddColumnWithDefault
    end

    add_concurrent_index :snippets, [:visibility_level, :secret]
    remove_concurrent_index :snippets, :visibility_level
  end

  def down
    add_concurrent_index :snippets, :visibility_level
    remove_concurrent_index :snippets, [:visibility_level, :secret]

    if column_exists?(:snippets, :secret)
      remove_column :snippets, :secret
    end
  end
end
