# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class ValueStreamPolicy < ::BasePolicy
      delegate { subject.namespace }
    end
  end
end
