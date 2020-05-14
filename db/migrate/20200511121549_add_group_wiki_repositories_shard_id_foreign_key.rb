# frozen_string_literal: true

class AddGroupWikiRepositoriesShardIdForeignKey < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_foreign_key :group_wiki_repositories, :shards, on_delete: :restrict # rubocop:disable Migration/AddConcurrentForeignKey
    end
  end

  def down
    with_lock_retries do
      remove_foreign_key :group_wiki_repositories, :shards
    end
  end
end
