# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class StageSummary
      def initialize(project, from:, current_user:)
        @project = project
        @from = from
        @current_user = current_user
      end

      def data
        [serialize(Summary::Issue.new(project: @project, from: @from, current_user: @current_user)),
         serialize(Summary::Commit.new(project: @project, from: @from)),
         serialize(Summary::Deploy.new(project: @project, from: @from))]
      end

      private

      def serialize(summary_object)
        AnalyticsSummarySerializer.new.represent(summary_object)
      end
    end
  end
end
