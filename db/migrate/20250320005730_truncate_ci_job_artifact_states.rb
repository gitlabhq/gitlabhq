# frozen_string_literal: true

class TruncateCiJobArtifactStates < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  disable_ddl_transaction!

  def up
    return unless Gitlab.com?

    truncate_tables!('ci_job_artifact_states')
  end

  def down
    # no-op
  end
end
