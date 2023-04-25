# frozen_string_literal: true

class ReRemoveProjectsCiJobArtifactsProjectIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    return unless foreign_key_exists?(:ci_job_artifacts, :projects, name: "fk_rails_9862d392f9")

    with_lock_retries do
      execute('LOCK projects, ci_job_artifacts IN ACCESS EXCLUSIVE MODE') if transaction_open?

      remove_foreign_key_if_exists(:ci_job_artifacts, :projects, name: "fk_rails_9862d392f9")
    end
  end

  def down
    # no-op, since the FK will be added via rollback by prior-migration
  end
end
