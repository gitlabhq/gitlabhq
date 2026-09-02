# frozen_string_literal: true

# Read-only model for the abuse_report_uploads partition of the uploads table.
# Geo::AbuseReportUpload reads the same partition, but it lives in ee/ and so is
# not available to CE code such as the organization transfer services.
module AntiAbuse
  class AbuseReportUpload < ::Upload
    self.table_name = 'abuse_report_uploads'
    self.primary_key = :id
  end
end
