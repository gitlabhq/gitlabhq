# frozen_string_literal: true

class AddFailedDeletionCountAndNextDeleteAtToContainerRepositories < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    add_column :container_repositories, :failed_deletion_count,
      :integer, default: 0, null: false, if_not_exists: true

    add_column :container_repositories, :next_delete_attempt_at,
      :datetime_with_timezone, if_not_exists: true
  end
end
