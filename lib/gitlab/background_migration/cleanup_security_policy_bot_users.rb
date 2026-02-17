# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class CleanupSecurityPolicyBotUsers < BatchedMigrationJob
      operation_name :cleanup_security_policy_bot_users
      feature_category :security_policy_management

      SECURITY_POLICY_BOT_TYPE = 10
      PREMIUM_PLANS = %w[premium silver premium_trial].freeze

      # rubocop:disable Database/AvoidScopeTo -- supporting index: index_users_on_user_type_and_id
      scope_to ->(relation) { relation.where(user_type: SECURITY_POLICY_BOT_TYPE) }
      # rubocop:enable Database/AvoidScopeTo

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(<<~SQL)
            WITH sub_batch AS MATERIALIZED (
              #{sub_batch.select(:id).limit(sub_batch_size).to_sql}
            ),
            users_to_delete AS MATERIALIZED (
              SELECT users.id
              FROM sub_batch AS users
              INNER JOIN members ON members.user_id = users.id
              INNER JOIN projects ON projects.id = members.source_id
              INNER JOIN namespaces ON namespaces.id = projects.namespace_id
              INNER JOIN gitlab_subscriptions ON gitlab_subscriptions.namespace_id = namespaces.traversal_ids[1]
              INNER JOIN plans ON plans.id = gitlab_subscriptions.hosted_plan_id
              WHERE members.source_type = 'Project'
                AND members.type = 'ProjectMember'
                AND plans.name IN (#{PREMIUM_PLANS.map { |plan| connection.quote(plan) }.join(', ')})
              LIMIT #{sub_batch_size}
            )
            DELETE FROM users WHERE id IN (SELECT id FROM users_to_delete)
          SQL
        end
      end
    end
  end
end
