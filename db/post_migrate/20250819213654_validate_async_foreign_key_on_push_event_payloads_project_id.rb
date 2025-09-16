# frozen_string_literal: true

class ValidateAsyncForeignKeyOnPushEventPayloadsProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  # According to https://docs.gitlab.com/development/database/foreign_keys/#schedule-the-fk-to-be-validated
  # FK_NAME taken from https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201179/diffs#diff-content-2b082fc1831991d48d393026c0c6a4283cb3d159
  FK_NAME = :fk_2f8fdf5cac
  def up
    prepare_async_foreign_key_validation :push_event_payloads, name: FK_NAME
  end

  def down
    unprepare_async_foreign_key_validation :push_event_payloads, name: FK_NAME
  end
end
