# frozen_string_literal: true

class AddPresentOnDefaultBranchToVulnerabilities < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      add_column :vulnerabilities, :present_on_default_branch, :boolean, default: true, null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :vulnerabilities, :present_on_default_branch
    end
  end
end
