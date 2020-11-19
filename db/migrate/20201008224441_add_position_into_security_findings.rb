# frozen_string_literal: true

class AddPositionIntoSecurityFindings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :security_findings, :position, :integer
    end
  end

  def down
    with_lock_retries do
      remove_column :security_findings, :position
    end
  end
end
