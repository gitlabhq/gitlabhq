# frozen_string_literal: true

class RemoveTmpBigintFkForDeploymentsPhaseTwo < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  # A wraparound prevention vacuum on `deployments` cut this migration short, so
  # the foreign key survived. Retried in
  # RemoveTmpBigintFkForDeploymentsPhaseTwoRetry, since this version has already
  # been recorded and will not run again.
  def up; end

  def down; end
end
