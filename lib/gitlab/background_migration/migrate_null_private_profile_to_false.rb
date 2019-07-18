# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This class is responsible for migrating a range of users with private_profile == NULL to false
    class MigrateNullPrivateProfileToFalse
      # Temporary AR class for users
      class User < ActiveRecord::Base
        self.table_name = 'users'
      end

      def perform(start_id, stop_id)
        User.where(private_profile: nil, id: start_id..stop_id).update_all(private_profile: false)
      end
    end
  end
end
