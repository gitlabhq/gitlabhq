# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Serializers
      class Time
        DEFAULT_TIME = '2025-08-01T00:00:00.000Z'

        def serialize(value, example: nil)
          return unless defined?(ActiveSupport::TimeWithZone) && value.is_a?(ActiveSupport::TimeWithZone)

          return example if example

          DEFAULT_TIME
        end
      end
    end
  end
end
