# frozen_string_literal: true
class AddExpirationPolicyCompletedAtToContainerRepositories < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    add_column(:container_repositories, :expiration_policy_completed_at, :datetime_with_timezone)
  end

  def down
    remove_column(:container_repositories, :expiration_policy_completed_at)
  end
end
