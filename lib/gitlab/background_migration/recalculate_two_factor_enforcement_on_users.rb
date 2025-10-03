# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class RecalculateTwoFactorEnforcementOnUsers < BatchedMigrationJob
      HUMAN_USER_TYPE = 0

      operation_name :recalculate_two_factor_enforcement
      feature_category :system_access

      class Group < ::ApplicationRecord
        include FromUnion

        self.table_name = 'namespaces'
      end

      class GroupMember < ::ApplicationRecord
        self.table_name = 'members'

        belongs_to :group, foreign_key: 'source_id'

        default_scope { where(source_type: 'Namespace') } # rubocop:disable Cop/DefaultScope -- maintaining parity with model
      end

      class User < ::ApplicationRecord
        GUEST_ACCESS_LEVEL = 10

        self.table_name = 'users'

        has_many :group_members,
          -> { where(requested_at: nil).where(access_level: GUEST_ACCESS_LEVEL..) },
          class_name: 'GroupMember'
        has_many :groups, through: :group_members

        def update_two_factor_requirement
          periods = expanded_groups_requiring_two_factor_authentication.pluck(:two_factor_grace_period) # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- maintaining parity with model

          self.require_two_factor_authentication_from_group = periods.any?
          self.two_factor_grace_period = periods.min || User.column_defaults['two_factor_grace_period']

          return unless require_two_factor_authentication_from_group_changed?

          Gitlab::AppLogger.info({ message: 'User 2FA enforcement from group changed.',
                                   user_id: id,
                                   from: require_two_factor_authentication_from_group_was,
                                   to: require_two_factor_authentication_from_group })

          save
        end

        def expanded_groups_requiring_two_factor_authentication
          return groups if groups.empty?

          Gitlab::ObjectHierarchy
            .new(groups)
            .all_objects
            .where(require_two_factor_authentication: true)
        end
      end

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.where(user_type: HUMAN_USER_TYPE).find_each do |user|
            user = User.find_by(id: user.id)
            user&.update_two_factor_requirement
          end
        end
      end
    end
  end
end
