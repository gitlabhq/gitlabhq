# frozen_string_literal: true

class AddExpirationPolicyStartedAtToContainerRepositories < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    add_column(:container_repositories, :expiration_policy_started_at, :datetime_with_timezone)
  end

  def down
    remove_column(:container_repositories, :expiration_policy_started_at)
  end
end
