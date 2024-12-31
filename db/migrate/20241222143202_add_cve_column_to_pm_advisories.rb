# frozen_string_literal: true

class AddCveColumnToPmAdvisories < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.8'

  def up
    with_lock_retries do
      add_column :pm_advisories, :cve, :text, null: true
    end

    add_text_limit :pm_advisories, :cve, 24
  end

  def down
    with_lock_retries do
      remove_column :pm_advisories, :cve
    end
  end
end
