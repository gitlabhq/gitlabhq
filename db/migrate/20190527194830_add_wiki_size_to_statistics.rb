# frozen_string_literal: true

class AddWikiSizeToStatistics < ActiveRecord::Migration[5.0]
  DOWNTIME = false

  def change
    add_column :project_statistics, :wiki_size, :bigint
  end
end
