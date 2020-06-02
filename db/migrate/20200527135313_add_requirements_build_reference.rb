# frozen_string_literal: true

class AddRequirementsBuildReference < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_requirements_management_test_reports_on_build_id'

  def up
    add_column :requirements_management_test_reports, :build_id, :bigint
    add_index :requirements_management_test_reports, :build_id, name: INDEX_NAME # rubocop:disable Migration/AddIndex

    with_lock_retries do
      add_foreign_key :requirements_management_test_reports, :ci_builds, column: :build_id, on_delete: :nullify # rubocop:disable Migration/AddConcurrentForeignKey
    end
  end

  def down
    with_lock_retries do
      remove_column :requirements_management_test_reports, :build_id
    end
  end
end
