# frozen_string_literal: true

module CycleAnalytics
  class GroupLevel
    include BaseMethods
    attr_reader :options

    def initialize(options:)
      @options = options
    end

    def summary
      @summary ||= ::Gitlab::CycleAnalytics::GroupStageSummary.new(options[:group],
                                                              from: options[:from],
                                                              current_user: options[:current_user]).data
    end

    def permissions(user: nil)
      STAGES.each_with_object({}) do |stage, obj|
        obj[stage] = true
      end
    end

    def stats
      @stats ||= STAGES.map do |stage_name|
        self[stage_name].as_json(serializer: GroupAnalyticsStageSerializer)
      end
    end
  end
end
