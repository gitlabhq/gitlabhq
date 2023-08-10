# frozen_string_literal: true

module Resolvers
  class AbuseReportResolver < BaseResolver
    description 'Retrieve an abuse report'

    type Types::AbuseReportType, null: true

    argument :id, Types::GlobalIDType[AbuseReport], required: true, description: 'ID of the abuse report.'

    def resolve(id:)
      ::AbuseReport.find_by_id(extract_abuse_report_id(id))
    end

    private

    def extract_abuse_report_id(gid)
      GitlabSchema.parse_gid(gid, expected_type: ::AbuseReport).model_id
    end
  end
end
