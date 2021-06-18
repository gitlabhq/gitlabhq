# frozen_string_literal: true

class AddDastSiteProfileIdFkToDastSiteProfilesBuilds < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :dast_site_profiles_builds, :dast_site_profiles, column: :dast_site_profile_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :dast_site_profiles_builds, column: :dast_site_profile_id
    end
  end
end
