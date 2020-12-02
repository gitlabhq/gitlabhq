# frozen_string_literal: true
#
class AddColumnToSecurityFindings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :security_findings, :uuid, :uuid
  end
end
