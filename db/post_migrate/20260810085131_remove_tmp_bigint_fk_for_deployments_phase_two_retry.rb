# frozen_string_literal: true

class RemoveTmpBigintFkForDeploymentsPhaseTwoRetry < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  # This migration exhausted its lock retries, so the foreign key survived.
  # Retried with a more aggressive timing configuration in
  # RemoveTmpBigintFkForDeploymentsPhaseTwoRetryTwo, since this version has
  # already been recorded and will not run again.
  def up; end

  def down; end
end
