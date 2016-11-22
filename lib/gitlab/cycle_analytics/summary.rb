module Gitlab
  module CycleAnalytics
    module Summary
      extend self

      def initialize(project, from:)
        @project = project
        @from = from
      end

      def data
        [serialize(issue),
         serialize(commit),
         serialize(deploy)]
      end

      private

      def serialize(summary_object)
        AnalyticsSummarySerializer.new.represent(summary_object).as_json
      end

      def issue
        Summary::Issue.new(project: @project, from: @from)
      end

      def deploy
        Summary::Deploy.new(project: @project, from: @from)
      end

      def commit
        Summary::Commit.new(project: @project, from: @from)
      end
    end
  end
end
