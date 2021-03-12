# frozen_string_literal: true

module Analytics
  module UsageTrends
    class MeasurementPolicy < BasePolicy
      delegate { :global }
    end
  end
end
