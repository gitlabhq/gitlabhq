# frozen_string_literal: true

class EnsureNoEmptyMilestoneTitles < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    loop do
      rows_updated = exec_update <<~SQL
        UPDATE milestones SET title = '%BLANK' WHERE id IN (SELECT id FROM milestones WHERE title = '' LIMIT 500)
      SQL
      break if rows_updated < 500
    end
  end

  def down; end
end
