# frozen_string_literal: true

class EnableBtreeGistExtension < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    execute 'CREATE EXTENSION IF NOT EXISTS btree_gist'
  end

  def down
    execute 'DROP EXTENSION IF EXISTS btree_gist'
  end
end
