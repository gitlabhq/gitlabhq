# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class MigrateUsersBioToUserDetails
      class User < ActiveRecord::Base
        self.table_name = 'users'
      end

      class UserDetails < ActiveRecord::Base
        self.table_name = 'user_details'
      end

      def perform(start_id, stop_id)
        relation = User
          .select("id AS user_id", "substring(COALESCE(bio, '') from 1 for 255) AS bio")
          .where("(COALESCE(bio, '') IS DISTINCT FROM '')")
          .where(id: (start_id..stop_id))

        ActiveRecord::Base.connection.execute <<-EOF.strip_heredoc
          INSERT INTO user_details
          (user_id, bio)
          #{relation.to_sql}
          ON CONFLICT (user_id)
          DO UPDATE SET
            "bio" = EXCLUDED."bio";
        EOF
      end
    end
  end
end
