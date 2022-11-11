# frozen_string_literal: true

module Ci
  module JobArtifacts
    class TrackArtifactReportService
      include Gitlab::Utils::UsageData

      REPORT_TRACKED = %i[test coverage].freeze

      def execute(pipeline)
        REPORT_TRACKED.each do |report|
          if pipeline.complete_and_has_reports?(Ci::JobArtifact.of_report_type(report))
            track_usage_event(event_name(report), pipeline.user_id)
          end
        end
      end

      def event_name(report)
        "i_testing_#{report}_report_uploaded"
      end
    end
  end
end
