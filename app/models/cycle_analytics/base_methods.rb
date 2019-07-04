# frozen_string_literal: true

module CycleAnalytics
  module BaseMethods
    STAGES = %i[issue plan code test review staging production].freeze

    def all_medians_by_stage
      STAGES.each_with_object({}) do |stage_name, medians_per_stage|
        medians_per_stage[stage_name] = self[stage_name].project_median
      end
    end

    def stats
      @stats ||= STAGES.map do |stage_name|
        self[stage_name].as_json
      end
    end

    def no_stats?
      stats.all? { |hash| hash[:value].nil? }
    end

    def [](stage_name)
      Gitlab::CycleAnalytics::Stage[stage_name].new(options: options)
    end
  end
end
