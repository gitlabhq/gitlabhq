# frozen_string_literal: true

class ValidateForeignKeyConstraintOnTodosOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  FK_NAME = :fk_78558e5d74

  def up
    # NOTE: FK was validated asynchronously in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208310
    validate_foreign_key :todos, :organization_id, name: FK_NAME
  end

  def down
    # Can be safely a no-op if we don't roll back the inconsistent data
  end
end
