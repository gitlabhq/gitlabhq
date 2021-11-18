# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Add user primary email to emails table if confirmed
    class AddPrimaryEmailToEmailsIfUserConfirmed
      INNER_BATCH_SIZE = 1_000

      # Stubbed class to access the User table
      class User < ActiveRecord::Base
        include ::EachBatch

        self.table_name = 'users'
        self.inheritance_column = :_type_disabled

        scope :confirmed, -> { where.not(confirmed_at: nil) }

        has_many :emails
      end

      # Stubbed class to access the Emails table
      class Email < ActiveRecord::Base
        self.table_name = 'emails'
        self.inheritance_column = :_type_disabled

        belongs_to :user
      end

      def perform(start_id, end_id)
        User.confirmed.where(id: start_id..end_id).select(:id, :email, :confirmed_at).each_batch(of: INNER_BATCH_SIZE) do |users|
          current_time = Time.now.utc

          attributes = users.map do |user|
            {
              user_id: user.id,
              email: user.email,
              confirmed_at: user.confirmed_at,
              created_at: current_time,
              updated_at: current_time
            }
          end

          Email.insert_all(attributes)
        end
        mark_job_as_succeeded(start_id, end_id)
      end

      private

      def mark_job_as_succeeded(*arguments)
        Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
          'AddPrimaryEmailToEmailsIfUserConfirmed',
          arguments
        )
      end
    end
  end
end
