# frozen_string_literal: true

module Types
  class MergeStrategyEnum < BaseEnum
    AutoMergeService.all_strategies_ordered_by_preference.each do |strat|
      value strat.upcase, value: strat, description: "Use the #{strat} merge strategy."
    end
  end
end
