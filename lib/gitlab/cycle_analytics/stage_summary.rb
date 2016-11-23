module Gitlab
  module CycleAnalytics
    class StageSummary
      def initialize(project, from:)
        @project = project
        @from = from
      end

      def data
        [serialize(Summary::Issue.new(project: @project, from: @from)),
         serialize(Summary::Commit.new(project: @project, from: @from)),
         serialize(Summary::Deploy.new(project: @project, from: @from))]
      end

      private

      def serialize(summary_object)
        AnalyticsSummarySerializer.new.represent(summary_object).as_json
      end
    end
  end
end
