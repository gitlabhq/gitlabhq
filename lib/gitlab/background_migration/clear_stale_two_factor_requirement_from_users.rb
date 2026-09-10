# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class ClearStaleTwoFactorRequirementFromUsers < BatchedMigrationJob
      HUMAN_USER_TYPE = 0
      MEMBER_SOURCE_TYPE = 'Namespace'

      operation_name :clear_stale_two_factor_requirement
      feature_category :system_access

      scope_to ->(relation) do # rubocop: disable Database/AvoidScopeTo -- supporting index: tmp_idx_users_on_id_where_two_factor_required_from_group ON users USING btree (id) WHERE ((require_two_factor_authentication_from_group = true) AND (user_type = 0))
        relation.where(
          require_two_factor_authentication_from_group: true,
          user_type: HUMAN_USER_TYPE
        )
      end

      class User < ::ApplicationRecord
        self.table_name = 'users'
      end

      def perform
        each_sub_batch do |sub_batch|
          user_ids = sub_batch.pluck(:id)

          next if user_ids.empty?

          stale_ids = user_ids - user_ids_with_enforcing_groups(user_ids)

          next if stale_ids.empty?

          clear_requirement(stale_ids)
        end
      end

      private

      # Counts strictly more groups as enforcing than the runtime calculation
      # (no plan or license gating), so finding none means the value is stale.
      def user_ids_with_enforcing_groups(user_ids)
        connection.select_values(
          ApplicationRecord.sanitize_sql_array([
            <<~SQL.squish,
              SELECT DISTINCT m.user_id
              FROM members m
              JOIN namespaces n ON n.id = m.source_id
              WHERE m.source_type  = :source_type
                AND m.requested_at IS NULL
                AND m.user_id      IN (:user_ids)
                AND EXISTS (
                  SELECT 1
                  FROM namespaces g
                  WHERE g.traversal_ids[1] = n.traversal_ids[1]
                    AND g.type = 'Group'
                    AND g.require_two_factor_authentication
                )
            SQL
            {
              user_ids: user_ids,
              source_type: MEMBER_SOURCE_TYPE
            }
          ])
        )
      end

      def clear_requirement(user_ids)
        User.where(id: user_ids).update_all(
          require_two_factor_authentication_from_group: false,
          two_factor_grace_period: User.column_defaults['two_factor_grace_period'],
          updated_at: Time.current
        )

        user_ids.each do |user_id|
          Gitlab::AppLogger.info({
            message: 'Stale user group 2FA enforcement cleared.',
            Labkit::Fields::GL_USER_ID => user_id,
            from: true,
            to: false
          })
        end
      end
    end
  end
end
