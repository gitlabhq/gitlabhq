# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ScheduleFillValidTimeForPagesDomainCertificates < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  MIGRATION = 'FillValidTimeForPagesDomainCertificate'
  BATCH_SIZE = 500
  BATCH_TIME = 5.minutes

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  class PagesDomain < ActiveRecord::Base
    include ::EachBatch

    self.table_name = 'pages_domains'
  end

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      PagesDomain.where.not(certificate: [nil, '']),
      MIGRATION,
      BATCH_TIME,
      batch_size: BATCH_SIZE)
  end

  def down
  end
end
