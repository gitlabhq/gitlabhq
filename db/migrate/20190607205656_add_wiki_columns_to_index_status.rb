# frozen_string_literal: true

class AddWikiColumnsToIndexStatus < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :index_statuses, :last_wiki_commit, :binary
    add_column :index_statuses, :wiki_indexed_at, :datetime_with_timezone
  end
end
