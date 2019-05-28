# frozen_string_literal: true

class AddLocalCachedMarkdownVersion < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :application_settings, :local_markdown_version, :integer, default: 0, null: false
  end
end
