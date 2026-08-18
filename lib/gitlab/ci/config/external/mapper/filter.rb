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
              kept = locations.select do |location|
                Rules.new(location[:rules]).evaluate(context).pass?
              end

              context.mark_all_includes_filtered_by_rules! if kept.empty? && locations.any?

              kept
            end
          end
        end
      end
    end
  end
end
