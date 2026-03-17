# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Concerns
      module Serializable
        private

        def serializable?(value)
          return false if value.is_a?(Proc)
          return false if defined?(ActiveSupport::TimeWithZone) && value.is_a?(ActiveSupport::TimeWithZone)
          return false if value.is_a?(Time)

          true
        end
      end
    end
  end
end
