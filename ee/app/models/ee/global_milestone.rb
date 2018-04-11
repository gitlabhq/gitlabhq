module EE
  module GlobalMilestone
    def supports_weight?
      false
    end

    # Legacy group milestones or dashboard milestones (grouped by title)
    # can't present Burndown charts since they don't have
    # proper limits set.
    def supports_burndown_charts?
      false
    end
  end
end
