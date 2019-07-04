# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class GroupStageSummary
      def initialize(group, from:, current_user:)
        @group = group
        @from = from
        @current_user = current_user
      end

      def data
        [serialize(Summary::Group::Issue.new(group: @group, from: @from, current_user: @current_user)),
         serialize(Summary::Group::Deploy.new(group: @group, from: @from))]
      end

      private

      def serialize(summary_object)
        AnalyticsSummarySerializer.new.represent(summary_object)
      end
    end
  end
end
