# frozen_string_literal: true

class AddComplianceFrameworksToApplicationSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :application_settings, :compliance_frameworks, :integer, limit: 2, array: true, default: [], null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :application_settings, :compliance_frameworks
    end
  end
end
