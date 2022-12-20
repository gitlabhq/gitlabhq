# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        class Mapper
          # Filters locations according to rules
          class Filter < Base
            private

            def process_without_instrumentation(locations)
              locations.select do |location|
                Rules.new(location[:rules]).evaluate(context).pass?
              end
            end
          end
        end
      end
    end
  end
end
