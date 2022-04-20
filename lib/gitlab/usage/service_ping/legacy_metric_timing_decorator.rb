# frozen_string_literal: true

module Gitlab
  module Usage
    module ServicePing
      class LegacyMetricTimingDecorator < SimpleDelegator
        attr_reader :duration

        delegate :class, :is_a?, :kind_of?, to: :__getobj__

        def initialize(value, duration)
          @duration = duration
          super(value)
        end
      end
    end
  end
end
