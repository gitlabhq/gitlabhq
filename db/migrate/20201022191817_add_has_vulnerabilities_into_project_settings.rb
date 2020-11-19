# frozen_string_literal: true

class AddHasVulnerabilitiesIntoProjectSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :project_settings, :has_vulnerabilities, :boolean, default: false, null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :project_settings, :has_vulnerabilities
    end
  end
end
