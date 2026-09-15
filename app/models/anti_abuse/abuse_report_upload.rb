# frozen_string_literal: true

# Partition-bound model for the abuse_report_uploads partition of the uploads
# table: SQL issued through it names that partition, not the uploads parent.
# We bind it so an update can't hit unrelated rows in other partitions.
# It also lets Gitlab::Organizations::TransferTracker credit the change to
# abuse_report_uploads alone, instead of every partition of uploads.
# Geo::AbuseReportUpload binds the same partition but lives in ee/, so it
# isn't available to CE code such as the organization transfer services.
module AntiAbuse
  class AbuseReportUpload < ::Upload
    self.table_name = 'abuse_report_uploads'
  end
end
