module EE
  module Milestone
    def supports_weight?
      project&.feature_available?(:issue_weights)
    end
  end
end
