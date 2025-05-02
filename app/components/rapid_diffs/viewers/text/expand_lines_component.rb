# frozen_string_literal: true

module RapidDiffs
  module Viewers
    module Text
      ICON_NAMES = {
        up: 'expand-up',
        down: 'expand-down',
        both: 'expand'
      }.freeze

      class ExpandLinesComponent < ViewComponent::Base
        def initialize(directions:)
          @directions = directions
        end

        def icon_name(direction)
          ICON_NAMES[direction]
        end

        def label(direction)
          case direction
          when :up   then s_('RapidDiffs|Show lines before')
          when :down then s_('RapidDiffs|Show lines after')
          when :both then s_('RapidDiffs|Show hidden lines')
          end
        end
      end
    end
  end
end
