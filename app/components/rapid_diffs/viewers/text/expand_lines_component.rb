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
        def initialize(direction:)
          @direction = direction
        end

        def icon_name
          ICON_NAMES[@direction]
        end
      end
    end
  end
end
