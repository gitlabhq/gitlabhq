# frozen_string_literal: true

module Gitlab::Ci
  module Badge
    module Coverage
      ##
      # Class that represents a coverage badge template.
      #
      # Template object will be passed to badge.svg.erb template.
      #
      class Template < Badge::Template
        STATUS_COLOR = {
          good: '#4c1',
          acceptable: '#a3c51c',
          medium: '#dfb317',
          low: '#e05d44',
          unknown: '#9f9f9f'
        }.freeze
        COVERAGE_MAX = 100
        COVERAGE_MIN = 0
        MIN_GOOD_DEFAULT = 95
        MIN_ACCEPTABLE_DEFAULT = 90
        MIN_MEDIUM_DEFAULT = 75

        def initialize(badge)
          @status = badge.status
          @min_good = badge.customization[:min_good]
          @min_acceptable = badge.customization[:min_acceptable]
          @min_medium = badge.customization[:min_medium]
          super
        end

        def value_text
          @status ? ("%.2f%%" % @status) : 'unknown'
        end

        def value_width
          @status ? 54 : 58
        end

        def min_good_value
          if @min_good && @min_good.between?(3, COVERAGE_MAX)
            @min_good
          else
            MIN_GOOD_DEFAULT
          end
        end

        def min_acceptable_value
          if @min_acceptable && @min_acceptable.between?(2, min_good_value - 1)
            @min_acceptable
          else
            [MIN_ACCEPTABLE_DEFAULT, (min_good_value - 1)].min
          end
        end

        def min_medium_value
          if @min_medium && @min_medium.between?(1, min_acceptable_value - 1)
            @min_medium
          else
            [MIN_MEDIUM_DEFAULT, (min_acceptable_value - 1)].min
          end
        end

        def value_color
          case @status
          when min_good_value..COVERAGE_MAX then STATUS_COLOR[:good]
          when min_acceptable_value..min_good_value then STATUS_COLOR[:acceptable]
          when min_medium_value..min_acceptable_value then STATUS_COLOR[:medium]
          when COVERAGE_MIN..min_medium_value then STATUS_COLOR[:low]
          else
            STATUS_COLOR[:unknown]
          end
        end
      end
    end
  end
end
