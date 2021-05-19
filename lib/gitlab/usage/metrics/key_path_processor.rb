# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      class KeyPathProcessor
        class << self
          def process(key_path, value)
            unflatten(key_path.split('.'), value)
          end

          private

          def unflatten(keys, value)
            loop do
              value = { keys.pop.to_sym => value }

              break if keys.blank?
            end

            value
          end
        end
      end
    end
  end
end
