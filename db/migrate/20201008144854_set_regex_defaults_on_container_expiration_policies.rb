# frozen_string_literal: true

class SetRegexDefaultsOnContainerExpirationPolicies < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      change_column_default :container_expiration_policies, :name_regex, '.*'
      change_column_default :container_expiration_policies, :enabled, false
    end
  end

  def down
    with_lock_retries do
      change_column_default :container_expiration_policies, :name_regex, nil
      change_column_default :container_expiration_policies, :enabled, true
    end
  end
end
