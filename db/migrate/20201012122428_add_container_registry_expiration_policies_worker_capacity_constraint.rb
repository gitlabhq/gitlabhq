# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddContainerRegistryExpirationPoliciesWorkerCapacityConstraint < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  CONSTRAINT_NAME = 'app_settings_registry_exp_policies_worker_capacity_positive'

  disable_ddl_transaction!

  def up
    add_check_constraint :application_settings, 'container_registry_expiration_policies_worker_capacity >= 0', CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :application_settings, CONSTRAINT_NAME
  end
end
