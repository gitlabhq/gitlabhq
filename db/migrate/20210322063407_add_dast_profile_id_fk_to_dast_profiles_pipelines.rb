# frozen_string_literal: true

class AddDastProfileIdFkToDastProfilesPipelines < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :dast_profiles_pipelines, :dast_profiles, column: :dast_profile_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :dast_profiles_pipelines, column: :dast_profile_id
    end
  end
end
