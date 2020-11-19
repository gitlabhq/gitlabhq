# frozen_string_literal: true

class AddRepositoryReadOnlyToSnippets < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :snippets, :repository_read_only, :boolean, default: false, null: false
  end
end
