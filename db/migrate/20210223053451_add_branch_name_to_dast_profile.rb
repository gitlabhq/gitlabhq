# frozen_string_literal: true

class AddBranchNameToDastProfile < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :dast_profiles, :branch_name, :text
    end

    add_text_limit :dast_profiles, :branch_name, 255
  end

  def down
    with_lock_retries do
      remove_column :dast_profiles, :branch_name
    end
  end
end
