# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class GroupStageSummary
      def initialize(group, from:, current_user:, options:)
        @group = group
        @from = from
        @current_user = current_user
        @options = options
      end

      def data
        [serialize(Summary::Group::Issue.new(group: @group, from: @from, current_user: @current_user, options: @options)),
         serialize(Summary::Group::Deploy.new(group: @group, from: @from, options: @options))]
      end

      private

      def serialize(summary_object)
        AnalyticsSummarySerializer.new.represent(summary_object)
      end
    end
  end
end
