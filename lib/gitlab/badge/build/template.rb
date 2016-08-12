module Gitlab
  module Badge
    class Build
      ##
      # Class that represents a build badge template.
      #
      # Template object will be passed to badge.svg.erb template.
      #
      class Template
        STATUS_COLOR = {
          success: '#4c1',
          failed: '#e05d44',
          running: '#dfb317',
          pending: '#dfb317',
          canceled: '#9f9f9f',
          skipped: '#9f9f9f',
          unknown: '#9f9f9f'
        }

        def initialize(status)
          @status = status
        end

        def key_text
          'build'
        end

        def value_text
          @status
        end

        def key_width
          38
        end

        def value_width
          54
        end

        def key_color
          '#555'
        end

        def value_color
          STATUS_COLOR[@status.to_sym] ||
            STATUS_COLOR[:unknown]
        end

        def key_text_anchor
          key_width / 2
        end

        def value_text_anchor
          key_width + (value_width / 2)
        end

        def width
          key_width + value_width
        end
      end
    end
  end
end
