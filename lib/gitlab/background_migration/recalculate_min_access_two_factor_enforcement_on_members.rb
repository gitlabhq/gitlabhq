# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class RecalculateMinAccessTwoFactorEnforcementOnMembers < BatchedMigrationJob
      HUMAN_USER_TYPE = 0
      MINIMAL_ACCESS_LEVEL = 5
      MEMBER_SOURCE_TYPE = 'Namespace'

      operation_name :recalculate_min_access_two_factor_enforcement
      feature_category :system_access

      scope_to ->(relation) do # rubocop: disable Database/AvoidScopeTo -- tmp_index is used
        relation.where(
          access_level: MINIMAL_ACCESS_LEVEL,
          source_type: MEMBER_SOURCE_TYPE,
          requested_at: nil
        )
      end

      class User < ::ApplicationRecord
        self.table_name = 'users'
      end

      def perform
        each_sub_batch do |sub_batch|
          distinct_minimal_access_member_user_ids = sub_batch.distinct.pluck(:user_id)

          next if distinct_minimal_access_member_user_ids.empty?

          grace_periods = fetch_minimum_grace_periods(distinct_minimal_access_member_user_ids)
          apply_updates(distinct_minimal_access_member_user_ids, grace_periods)
        end
      end

      private

      # Computes aggregate MIN(two_factor_grace_period) per user across the ENTIRE group
      # hierarchy (root + all descendant groups) for each minimal_access membership
      # (https://gitlab.com/gitlab-org/gitlab/-/work_items/534094)
      #
      # This matches User#all_expanded_groups semantics: subgroup 2FA enforcement applies
      # to top-level group members, and the shortest grace period in the hierarchy wins.
      # We join all namespaces sharing the same traversal_ids[1] (root) and filter to
      # type = 'Group' to exclude project and user namespaces.
      #
      # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/204948/diffs#4ed0c03b53dbc8320da88e7887465514cd9e90a4
      # to understand how `Gitlab::ObjectHierarchy` was replaced in SQL.
      #
      # Max membership_count per user is noted here: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235857#note_3409035596
      #
      # Returns a hash in the format: { user_id1: grace_period, user_id2: grace_period..}
      #
      def fetch_minimum_grace_periods(user_ids)
        rows = connection.select_all(
          ApplicationRecord.sanitize_sql_array([
            <<~SQL.squish,
              SELECT m.user_id,
                     MIN(g.two_factor_grace_period) FILTER (
                       WHERE g.require_two_factor_authentication
                     ) AS grace_period
              FROM members m
              JOIN namespaces n   ON n.id   = m.source_id
              LEFT JOIN namespaces g
                ON g.traversal_ids[1] = n.traversal_ids[1]
                AND g.type = 'Group'
              WHERE m.source_type  = :source_type
                AND m.access_level = :access_level
                AND m.requested_at IS NULL
                AND m.user_id      IN (:user_ids)
              GROUP BY m.user_id
            SQL
            {
              user_ids: user_ids,
              access_level: MINIMAL_ACCESS_LEVEL,
              source_type: MEMBER_SOURCE_TYPE
            }
          ])
        )

        rows.each_with_object({}) { |row, hash| hash[row['user_id']] = row['grace_period'] }
      end

      def apply_updates(user_ids, grace_periods)
        default_grace = User.column_defaults['two_factor_grace_period']

        User
          .where(id: user_ids, user_type: HUMAN_USER_TYPE)
          .select(:id, :require_two_factor_authentication_from_group)
          .find_each do |user|
            new_grace_period = grace_periods[user.id]
            new_required     = !new_grace_period.nil?

            next if new_required == user.require_two_factor_authentication_from_group

            User.where(id: user.id).update_all(
              require_two_factor_authentication_from_group: new_required,
              two_factor_grace_period: new_grace_period || default_grace,
              updated_at: Time.current # update_all doesn't instantiate models
            )

            Gitlab::AppLogger.info({
              message: 'Minimal_access user group 2FA enforcement changed.',
              Labkit::Fields::GL_USER_ID => user.id,
              from: user.require_two_factor_authentication_from_group,
              to: new_required
            })
          end
      end
    end
  end
end
