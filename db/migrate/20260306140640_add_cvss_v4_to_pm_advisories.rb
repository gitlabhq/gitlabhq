# frozen_string_literal: true

# See https://docs.gitlab.com/development/migration_style_guide/
# for more information on how to write migrations for GitLab.

class AddCvssV4ToPmAdvisories < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :pm_advisories, :cvss_v4, :text, null: true, if_not_exists: true
    end

    add_text_limit :pm_advisories, :cvss_v4, 180, validate: false
  end

  def down
    with_lock_retries do
      remove_column :pm_advisories, :cvss_v4, if_exists: true
    end
  end
end
