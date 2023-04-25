# frozen_string_literal: true

class RemoveProjectsCiJobArtifactsProjectIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    return if Gitlab.com? # unsafe migration, skip on GitLab.com due to https://gitlab.com/groups/gitlab-org/-/epics/7249#note_819625526
    return unless foreign_key_exists?(:ci_job_artifacts, :projects, name: "fk_rails_9862d392f9")

    with_lock_retries do
      execute('LOCK projects, ci_job_artifacts IN ACCESS EXCLUSIVE MODE') if transaction_open?

      remove_foreign_key_if_exists(:ci_job_artifacts, :projects, name: "fk_rails_9862d392f9")
    end
  end

  def down
    add_concurrent_foreign_key(:ci_job_artifacts, :projects, name: "fk_rails_9862d392f9", column: :project_id, target_column: :id, on_delete: :cascade)
  end
end
