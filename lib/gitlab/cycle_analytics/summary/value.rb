# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module Summary
      class Value
        attr_reader :value

        def raw_value
          value
        end

        def to_s
          raise NotImplementedError
        end

        class None < self
          def raw_value
            0
          end

          def to_i
            raw_value
          end

          def to_s
            '-'
          end
        end

        class Numeric < self
          def initialize(value)
            @value = value
          end

          def to_s
            value == 0 ? '0' : value.to_s
          end

          def to_i
            raw_value
          end
        end

        class PrettyNumeric < Numeric
          def to_s
            # 0 is shown as -
            (value || 0).nonzero? ? super : None.new.to_s
          end
        end
      end
    end
  end
end
