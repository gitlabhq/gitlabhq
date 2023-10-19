# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Project
      module Sample
        class DateCalculator
          include Gitlab::Utils::StrongMemoize

          def initialize(dates)
            @dates = dates.dup
            @dates.compact!
            @dates.sort!
            @dates.map! { |date| date.to_time.to_f }
          end

          def closest_date_to_average
            strong_memoize(:closest_date_to_average) do
              next if @dates.empty?

              average_date = (@dates.first + @dates.last) / 2.0
              closest_date = @dates.min_by { |date| (date - average_date).abs }
              Time.zone.at(closest_date)
            end
          end

          def calculate_by_closest_date_to_average(date)
            return date unless closest_date_to_average && closest_date_to_average.past?

            date + (Time.current - closest_date_to_average).seconds
          end
        end
      end
    end
  end
end
