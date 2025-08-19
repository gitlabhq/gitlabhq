# frozen_string_literal: true

class AddOrganizationIdConstraintOnCiRunnerMachines < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  disable_ddl_transaction!

  TABLE_NAME = 'ci_runner_machines'
  CONSTRAINT_NAME = 'check_organization_id_nullness'

  def up
    add_check_constraint(
      "instance_type_#{TABLE_NAME}", 'organization_id IS NULL', CONSTRAINT_NAME, validate: false
    )
    %w[group_type project_type].each do |runner_type|
      add_check_constraint(
        "#{runner_type}_#{TABLE_NAME}", 'organization_id IS NOT NULL', CONSTRAINT_NAME, validate: false)
    end
  end

  def down
    %w[instance_type group_type project_type].each do |runner_type|
      remove_check_constraint("#{runner_type}_#{TABLE_NAME}", CONSTRAINT_NAME)
    end
  end
end
