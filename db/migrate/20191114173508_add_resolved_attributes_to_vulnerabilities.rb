# frozen_string_literal: true

class AddResolvedAttributesToVulnerabilities < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    add_column :vulnerabilities, :resolved_by_id, :bigint
    add_column :vulnerabilities, :resolved_at, :datetime_with_timezone
  end

  def down
    remove_column :vulnerabilities, :resolved_at
    remove_column :vulnerabilities, :resolved_by_id
  end
end
