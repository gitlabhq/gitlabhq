# frozen_string_literal: true

module CycleAnalytics
  class GroupLevel
    include LevelBase
    attr_reader :options, :group

    def initialize(group:, options:)
      @group = group
      @options = options.merge(group: group)
    end

    def summary
      @summary ||= ::Gitlab::CycleAnalytics::GroupStageSummary.new(group,
                                                              from: options[:from],
                                                              current_user: options[:current_user]).data
    end

    def permissions(*)
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
