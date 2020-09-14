# frozen_string_literal: true

class EnableBtreeGistExtension < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    create_extension :btree_gist
  end

  def down
    drop_extension :btree_gist
  end
end
