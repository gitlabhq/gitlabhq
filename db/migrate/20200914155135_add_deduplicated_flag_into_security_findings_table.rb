# frozen_string_literal: true

class AddDeduplicatedFlagIntoSecurityFindingsTable < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :security_findings, :deduplicated, :boolean, default: false, null: false
  end
end
