# frozen_string_literal: true

class AddMissingInstanceToServicess < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  # This is a corrective migration to keep the instance column.
  # Upgrade from 12.7 to 12.9 removes the instance column as it was first added
  # in the normal migration and then removed in the post migration.
  #
  # 12.8 removed the instance column in a post deployment migration https://gitlab.com/gitlab-org/gitlab/-/merge_requests/24885
  # 12.9 added the instance column in a normal migration https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25714
  #
  # rubocop:disable Migration/AddColumnWithDefault
  # rubocop:disable Migration/UpdateLargeTable
  def up
    unless column_exists?(:services, :instance)
      add_column_with_default(:services, :instance, :boolean, default: false)
    end
  end
  # rubocop:enable Migration/AddColumnWithDefault
  # rubocop:enable Migration/UpdateLargeTable

  def down
    # Does not apply
  end
end
