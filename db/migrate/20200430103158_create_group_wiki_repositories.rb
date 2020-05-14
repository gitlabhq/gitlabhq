# frozen_string_literal: true

class CreateGroupWikiRepositories < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    create_table :group_wiki_repositories, id: false do |t|
      t.bigint :shard_id, null: false, index: true
      t.bigint :group_id, null: false, index: false, primary_key: true, default: nil

      # The limit is added in db/migrate/20200511120430_add_group_wiki_repositories_disk_path_limit.rb
      t.text :disk_path, null: false, index: { unique: true } # rubocop:disable Migration/AddLimitToTextColumns
    end
  end
end
