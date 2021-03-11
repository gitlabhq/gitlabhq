# frozen_string_literal: true

class AddInfoColumnIntoSecurityScansTable < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :security_scans, :info, :jsonb, null: false, default: {}
  end
end
