# frozen_string_literal: true

class AddConfirmedAttributesToVulnerabilities < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :vulnerabilities, :confirmed_by_id, :bigint
    add_column :vulnerabilities, :confirmed_at, :datetime_with_timezone
  end
end
