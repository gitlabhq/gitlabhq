# frozen_string_literal: true

module Resolvers
  module Ci
    class TestReportSummaryResolver < BaseResolver
      type ::Types::Ci::TestReportSummaryType, null: true

      alias_method :pipeline, :object

      def resolve(**args)
        TestReportSummarySerializer
          .new(project: pipeline.project, current_user: @current_user)
          .represent(pipeline.test_report_summary)
      end
    end
  end
end
