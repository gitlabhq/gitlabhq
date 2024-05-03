# frozen_string_literal: true

class BackfillDeploymentApprovalData < Gitlab::Database::Migration[2.2]
  milestone '17.0'
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  BATCH_SIZE = 500

  def up
    protected_environments_model = define_batchable_model('protected_environments')

    protected_environments_model.each_batch(of: BATCH_SIZE) do |relation|
      connection.execute(
        <<~SQL
          INSERT INTO protected_environment_approval_rules
                      (protected_environment_id,
                       created_at,
                       updated_at,
                       required_approvals,
                       access_level,
                       user_id,
                       group_id,
                       group_inheritance_type)
          SELECT protected_environments.id,
                 Now(),
                 Now(),
                 protected_environments.required_approval_count,
                 protected_environment_deploy_access_levels.access_level,
                 protected_environment_deploy_access_levels.user_id,
                 protected_environment_deploy_access_levels.group_id,
                 protected_environment_deploy_access_levels.group_inheritance_type

          FROM
            protected_environment_deploy_access_levels
            INNER JOIN protected_environments ON protected_environments.id = protected_environment_deploy_access_levels.protected_environment_id
          WHERE
            protected_environments.required_approval_count > 0
            AND NOT EXISTS (
              SELECT
                1
              FROM
                protected_environment_approval_rules
              WHERE
                protected_environment_id = protected_environments.id
            )
            AND protected_environments.id IN (#{relation.select(:id).to_sql})
        SQL
      )
    end
  end

  def down
    # noop
  end
end
