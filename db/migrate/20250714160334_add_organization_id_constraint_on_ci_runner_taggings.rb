# frozen_string_literal: true

class AddOrganizationIdConstraintOnCiRunnerTaggings < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  disable_ddl_transaction!

  TABLE_NAME = 'ci_runner_taggings'
  CONSTRAINT_NAME = 'check_organization_id_nullness'

  def up
    add_check_constraint(
      "#{TABLE_NAME}_instance_type", 'organization_id IS NULL', CONSTRAINT_NAME, validate: false
    )
    %w[group_type project_type].each do |runner_type|
      add_check_constraint(
        "#{TABLE_NAME}_#{runner_type}", 'organization_id IS NOT NULL', CONSTRAINT_NAME, validate: false)
    end
  end

  def down
    %w[instance_type group_type project_type].each do |runner_type|
      remove_check_constraint("#{TABLE_NAME}_#{runner_type}", CONSTRAINT_NAME)
    end
  end
end
