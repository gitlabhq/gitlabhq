# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class PurgeStaleSecurityScans # rubocop:disable Migration/BatchedMigrationBaseClass
      class SecurityScan < ::ApplicationRecord
        include EachBatch

        STALE_AFTER = 90.days

        self.table_name = 'security_scans'

        # Otherwise the schema_spec fails
        validates :info, json_schema: { filename: 'security_scan_info' }

        enum status: { succeeded: 1, purged: 6 }

        scope :to_purge, -> { where('id <= ?', last_stale_record_id) }
        scope :by_range, ->(range) { where(id: range) }

        def self.last_stale_record_id
          where('created_at < ?', STALE_AFTER.ago).order(created_at: :desc).first
        end
      end

      def perform(_start_id, _end_id); end
    end
  end
end

Gitlab::BackgroundMigration::PurgeStaleSecurityScans.prepend_mod
