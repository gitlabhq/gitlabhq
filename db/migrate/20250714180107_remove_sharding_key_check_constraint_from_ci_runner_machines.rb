# frozen_string_literal: true

class RemoveShardingKeyCheckConstraintFromCiRunnerMachines < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  CONSTRAINT_NAME = 'check_sharding_key_id_nullness'

  def up
    # no-op to fix https://gitlab.com/gitlab-com/gl-infra/production/-/issues/20245
  end

  def down
    # no-op to fix https://gitlab.com/gitlab-com/gl-infra/production/-/issues/20245
  end
end
