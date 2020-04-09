# frozen_string_literal: true

class PopulateCanonicalEmails < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class User < ActiveRecord::Base
    include EachBatch

    self.table_name = 'users'

    scope :with_gmail, -> { select(:id, :email).where("email ILIKE '%gmail.com'") }
  end

  # Limited to *@gmail.com addresses only as a first iteration, because we know
  # Gmail ignores `.` appearing in the Agent name, as well as anything after `+`

  def up
    # batch size is the default, 1000
    migration = Gitlab::BackgroundMigration::PopulateCanonicalEmails
    migration_name = migration.to_s.demodulize

    queue_background_migration_jobs_by_range_at_intervals(
      User.with_gmail,
      migration_name,
      1.minute)
  end

  def down
    # no-op
  end
end
