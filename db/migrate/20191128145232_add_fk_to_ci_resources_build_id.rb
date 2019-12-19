# frozen_string_literal: true

class AddFkToCiResourcesBuildId < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ci_resources, :ci_builds, column: :build_id, on_delete: :nullify
  end

  def down
    remove_foreign_key_if_exists :ci_resources, column: :build_id
  end
end
