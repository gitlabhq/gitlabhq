# frozen_string_literal: true

require "prawn"
require "prawn-svg"

module Gitlab
  module PDF
    module Security
      class VulnerabilitiesOverTime
        include Prawn::View

        PADDING = 10
        TOTAL_HEIGHT = 250

        def self.render(pdf, data: nil)
          new(pdf, data).render
        end

        def initialize(pdf, data)
          @pdf = pdf
          @data = process_raw(data)
          @y = pdf.cursor
        end

        def render
          return :noop if @data.blank?

          @pdf.bounding_box([0, @y], width: @pdf.bounds.right, height: TOTAL_HEIGHT) do
            draw_background

            @pdf.move_down PADDING

            # Fixed: nested box height should account for padding
            @pdf.bounding_box([PADDING, @pdf.cursor],
              width: @pdf.bounds.right - (PADDING * 2),
              height: TOTAL_HEIGHT) do
              draw_title
              draw_description

              # Get the full available width (which is the bounding box width)
              available_width = @pdf.bounds.right

              @pdf.move_down 20

              draw_svg(available_width)
            end
          end
        end

        private

        def draw_background
          @pdf.save_graphics_state
          @pdf.fill_color "F9F9F9"
          @pdf.fill_rectangle [0, @pdf.bounds.top], @pdf.bounds.right, TOTAL_HEIGHT
          @pdf.restore_graphics_state
        end

        def draw_title
          @pdf.text_box(
            s_('Vulnerabilities over time'),
            at: [0, @pdf.cursor],
            width: @pdf.bounds.right,
            height: 20,
            align: :left,
            style: :bold,
            size: 14
          )
          @pdf.move_down 20
        end

        def draw_description
          @pdf.text_box(
            s_("The number of vulnerabilities detected over time"),
            at: [0, @pdf.cursor],
            width: @pdf.bounds.right,
            height: 20,
            align: :left,
            size: 10
          )
          @pdf.move_down 10
        end

        def draw_svg(width)
          @pdf.svg @data,
            width: width,
            position: :center
        end

        def process_raw(data)
          return if data.blank?

          # Handle both direct SVG string and hash with 'svg' key
          svg = if data.is_a?(Hash)
                  data['svg'] || data[:svg]
                else
                  data
                end

          return if svg.blank?

          svg = CGI.unescape(svg).delete("\n")[%r{(<svg.*?</svg>)}, 1]

          return if svg.blank?

          svg
        end
      end
    end
  end
end
