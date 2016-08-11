module Gitlab
  module Badge
    module Coverage
      ##
      # Class that represents a coverage badge template.
      #
      # Template object will be passed to badge.svg.erb template.
      #
      class Template
        STATUS_COLOR = {
          good: '#4c1',
          acceptable: '#b0c',
          medium: '#dfb317',
          low: '#e05d44',
          unknown: '#9f9f9f'
        }

        def initialize(badge)
          @entity = badge.entity
          @status = badge.status
        end

        def key_text
          @entity.to_s
        end

        def value_text
          @status ? "#{@status}%" : 'unknown'
        end

        def key_width
          62
        end

        def value_width
          @status ? 32 : 58
        end

        def key_color
          '#555'
        end

        def value_color
          case @status
          when nil then STATUS_COLOR[:unknown]
          when 95..100 then STATUS_COLOR[:good]
          when 90..95 then STATUS_COLOR[:acceptable]
          when 75..90 then STATUS_COLOR[:medium]
          when 0..75 then STATUS_COLOR[:low]
          else
            STATUS_COLOR[:unknown]
          end
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
