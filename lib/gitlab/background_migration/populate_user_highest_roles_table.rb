# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This background migration creates records on user_highest_roles according to
    # the given user IDs range. IDs will load users with a left outer joins to
    # have a record for users without a Group or Project. One INSERT per ID is
    # issued.
    class PopulateUserHighestRolesTable
      BATCH_SIZE = 100

      # rubocop:disable Style/Documentation
      class User < ActiveRecord::Base
        self.table_name = 'users'

        scope :active, -> {
          where(state: 'active', user_type: nil, bot_type: nil)
            .where('ghost IS NOT TRUE')
        }
      end

      def perform(from_id, to_id)
        return unless User.column_names.include?('bot_type')

        (from_id..to_id).each_slice(BATCH_SIZE) do |ids|
          execute(
            <<-EOF
              INSERT INTO user_highest_roles (updated_at, user_id, highest_access_level)
              #{select_sql(from_id, to_id)}
              ON CONFLICT (user_id) DO
              UPDATE SET highest_access_level = EXCLUDED.highest_access_level
            EOF
          )
        end
      end

      private

      def select_sql(from_id, to_id)
        User
          .select('NOW() as updated_at, users.id, MAX(access_level) AS highest_access_level')
          .joins('LEFT OUTER JOIN members ON members.user_id = users.id AND members.requested_at IS NULL')
          .where(users: { id: active_user_ids(from_id, to_id) })
          .group('users.id')
          .to_sql
      end

      def active_user_ids(from_id, to_id)
        User.active.where(users: { id: from_id..to_id }).pluck(:id)
      end

      def execute(sql)
        @connection ||= ActiveRecord::Base.connection
        @connection.execute(sql)
      end
    end
  end
end
