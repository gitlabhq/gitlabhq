# frozen_string_literal: true

class AddGroupWikiRepositoriesDiskPathLimit < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_text_limit :group_wiki_repositories, :disk_path, 80
  end

  def down
    remove_text_limit :group_wiki_repositories, :disk_path
  end
end
