# frozen_string_literal: true

class SwitchRecordChangeTrackingToPCiRunnerMachinesTable < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def up
    # no-op due to https://gitlab.com/gitlab-com/gl-infra/production/-/issues/19476, retried in
    # RetrySwitchRecordChangeTrackingToPCiRunnerMachinesTable
  end

  def down
    # no-op
  end
end
