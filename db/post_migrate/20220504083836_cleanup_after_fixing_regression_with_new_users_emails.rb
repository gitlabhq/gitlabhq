# frozen_string_literal: true

class CleanupAfterFixingRegressionWithNewUsersEmails < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  BATCH_SIZE = 10_000

  # Stubbed class to access the User table
  class User < MigrationRecord
    include ::EachBatch

    self.table_name = 'users'
    self.inheritance_column = :_type_disabled

    scope :confirmed, -> { where.not(confirmed_at: nil) }

    has_many :emails
  end

  # Stubbed class to access the Emails table
  class Email < MigrationRecord
    self.table_name = 'emails'
    self.inheritance_column = :_type_disabled

    belongs_to :user
  end

  # rubocop: disable Layout/LineLength
  def up
    # Select confirmed users that do not have their primary email in the emails table,
    # and create the email record.
    not_exists_condition = 'NOT EXISTS (SELECT 1 FROM emails WHERE emails.email = users.email AND emails.user_id = users.id)'

    User.confirmed.each_batch(of: BATCH_SIZE) do |user_batch|
      user_batch.select(:id, :email, :confirmed_at).where(not_exists_condition).each do |user|
        current_time = Time.now.utc

        begin
          Email.create(
            user_id: user.id,
            email: user.email,
            confirmed_at: user.confirmed_at,
            created_at: current_time,
            updated_at: current_time
          )
        rescue StandardError => error
          Gitlab::AppLogger.error("Could not add primary email #{user.email} to emails for user with ID #{user.id} due to #{error}")
        end
      end
    end
  end
  # rubocop: enable Layout/LineLength

  def down
    # Intentionally left blank
  end
end
