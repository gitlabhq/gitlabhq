# frozen_string_literal: true

class AddWikiSizeToNamespaceStatistics < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :namespace_statistics, :wiki_size, :bigint, default: 0, null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :namespace_statistics, :wiki_size
    end
  end
end
