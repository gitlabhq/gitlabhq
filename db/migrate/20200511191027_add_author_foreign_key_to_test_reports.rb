# frozen_string_literal: true

class AddAuthorForeignKeyToTestReports < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_foreign_key :requirements_management_test_reports, :users, column: :author_id, on_delete: :nullify # rubocop:disable Migration/AddConcurrentForeignKey
    end
  end

  def down
    with_lock_retries do
      remove_foreign_key :requirements_management_test_reports, column: :author_id
    end
  end
end
