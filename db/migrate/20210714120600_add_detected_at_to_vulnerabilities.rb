# frozen_string_literal: true

class AddDetectedAtToVulnerabilities < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      add_column :vulnerabilities, :detected_at, :datetime_with_timezone
      change_column_default :vulnerabilities, :detected_at, -> { 'NOW()' }
    end
  end

  def down
    with_lock_retries do
      remove_column :vulnerabilities, :detected_at
    end
  end
end
