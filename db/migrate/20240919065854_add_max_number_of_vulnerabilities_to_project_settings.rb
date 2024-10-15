# frozen_string_literal: true

class AddMaxNumberOfVulnerabilitiesToProjectSettings < Gitlab::Database::Migration[2.2]
  TABLE_NAME = :project_settings
  COLUMN_NAME = :max_number_of_vulnerabilities

  milestone '17.5'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column TABLE_NAME, COLUMN_NAME, :integer
    end
  end

  def down
    with_lock_retries do
      remove_column TABLE_NAME, COLUMN_NAME
    end
  end
end
