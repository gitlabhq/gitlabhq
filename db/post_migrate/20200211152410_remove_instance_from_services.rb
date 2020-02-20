# frozen_string_literal: true

class RemoveInstanceFromServices < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    return unless column_exists?(:services, :instance)

    undo_rename_column_concurrently :services, :template, :instance
  end

  def down
    # This migration should not be rolled back because it
    # removes a column that got added in migrations that
    # have been reverted in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/24857
  end
end
