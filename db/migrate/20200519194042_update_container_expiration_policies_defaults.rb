# frozen_string_literal: true

class UpdateContainerExpirationPoliciesDefaults < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      change_column_default :container_expiration_policies, :cadence, '1d'
      change_column_default :container_expiration_policies, :keep_n, 10
      change_column_default :container_expiration_policies, :older_than, '90d'
    end
  end

  def down
    with_lock_retries do
      change_column_default :container_expiration_policies, :cadence, '7d'
      change_column_default :container_expiration_policies, :keep_n, nil
      change_column_default :container_expiration_policies, :older_than, nil
    end
  end
end
