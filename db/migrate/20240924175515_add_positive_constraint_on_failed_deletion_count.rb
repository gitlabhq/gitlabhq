# frozen_string_literal: true

class AddPositiveConstraintOnFailedDeletionCount < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_container_repositories_non_negative_failed_deletion_count'

  def up
    add_check_constraint :container_repositories, 'failed_deletion_count >= 0', CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :container_repositories, CONSTRAINT_NAME
  end
end
