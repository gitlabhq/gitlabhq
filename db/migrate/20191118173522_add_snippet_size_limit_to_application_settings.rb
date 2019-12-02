# frozen_string_literal: true

class AddSnippetSizeLimitToApplicationSettings < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    add_column :application_settings, :snippet_size_limit, :bigint, default: 50.megabytes, null: false
  end

  def down
    remove_column :application_settings, :snippet_size_limit
  end
end
