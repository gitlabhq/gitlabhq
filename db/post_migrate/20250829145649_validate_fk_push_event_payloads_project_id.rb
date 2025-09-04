# frozen_string_literal: true

class ValidateFkPushEventPayloadsProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  FK_NAME = :fk_2f8fdf5cac

  # NOTE: follow up to https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201179 &&
  #       https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201993
  def up
    validate_foreign_key :push_event_payloads, :project_id, name: FK_NAME
  end

  def down
    # noop
  end
end
