# frozen_string_literal: true

class EnableContainerExpirationPoliciesByDefault < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      change_column_default :container_expiration_policies, :enabled, true
    end
  end

  def down
    with_lock_retries do
      change_column_default :container_expiration_policies, :enabled, false
    end
  end
end
