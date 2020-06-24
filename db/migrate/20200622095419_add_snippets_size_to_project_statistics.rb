# frozen_string_literal: true

class AddSnippetsSizeToProjectStatistics < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :project_statistics, :snippets_size, :bigint
  end
end
