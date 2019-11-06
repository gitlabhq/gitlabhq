# frozen_string_literal: true

class AddReportTypeToVulnerabilities < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :vulnerabilities, :report_type, :integer, limit: 2
  end
end
