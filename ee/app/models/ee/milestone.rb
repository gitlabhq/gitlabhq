module EE
  module Milestone
    def supports_weight?
      parent&.feature_available?(:issue_weights)
    end

    def supports_burndown_charts?
      feature_name = group_milestone? ? :group_burndown_charts : :burndown_charts

      parent&.feature_available?(feature_name) && supports_weight?
    end
  end
end
