# frozen_string_literal: true

class RemoveStartDateColumnFromVulnerabilities < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  enable_lock_retries!

  def up
    remove_column :vulnerabilities, :start_date
  end

  def down
    add_column :vulnerabilities, :start_date, :date
  end
end
