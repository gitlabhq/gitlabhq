# frozen_string_literal: true

module Gitlab
  module Usage
    module ServicePing
      class LegacyMetricMetadataDecorator < SimpleDelegator
        attr_reader :duration, :error

        delegate :class, :is_a?, :kind_of?, :nil?, to: :__getobj__

        def initialize(value, duration, error: nil)
          @duration = duration
          @error = error
          super(value)
        end
      end
    end
  end
end
