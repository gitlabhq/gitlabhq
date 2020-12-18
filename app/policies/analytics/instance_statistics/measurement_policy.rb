# frozen_string_literal: true

module Analytics
  module InstanceStatistics
    class MeasurementPolicy < BasePolicy
      delegate { :global }
    end
  end
end
