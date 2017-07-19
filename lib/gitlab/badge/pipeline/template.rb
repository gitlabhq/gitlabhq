module Gitlab
  module Badge
    module Pipeline
      ##
      # Class that represents a pipeline badge template.
      #
      # Template object will be passed to badge.svg.erb template.
      #
      class Template < Badge::Template
        STATUS_RENAME = { 'success' => 'passed' }.freeze
        STATUS_COLOR = {
          success: '#4c1',
          failed: '#e05d44',
          running: '#dfb317',
          pending: '#dfb317',
          canceled: '#9f9f9f',
          skipped: '#9f9f9f',
          unknown: '#9f9f9f'
        }.freeze

        def initialize(badge)
          @entity = badge.entity
          @status = badge.status
        end

        def key_text
          @entity.to_s
        end

        def value_text
          STATUS_RENAME[@status.to_s] || @status.to_s
        end

        def key_width
          62
        end

        def value_width
          54
        end

        def value_color
          STATUS_COLOR[@status.to_sym] || STATUS_COLOR[:unknown]
        end
      end
    end
  end
end
