# frozen_string_literal: true

class PrepareAsyncFkValidationOnTodosOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  # NOTE: foreign key added in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/204559/diffs#diff-content-2b082fc1831991d48d393026c0c6a4283cb3d159
  FK_NAME = :fk_78558e5d74

  def up
    prepare_async_foreign_key_validation :todos, :organization_id, name: FK_NAME
  end

  def down
    unprepare_async_foreign_key_validation :todos, :organization_id, name: FK_NAME
  end
end
