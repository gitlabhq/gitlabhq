# frozen_string_literal: true

require "prawn"
require "prawn-svg"

module Gitlab
  module PDF
    module Security
      class GroupVulnerabilitiesHistory
        include Prawn::View

        # rubocop:disable Layout/LineLength -- data strings
        SEVERITY_ICONS = {
          critical: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><path fill="#dd2b0e" d="M6.706.185l4.088 2.31c.437.246.706.702.706 1.195v4.62c0 .493-.269.949-.706 1.195l-4.088 2.31a1.438 1.438 0 0 1-1.412 0l-4.088-2.31A1.376 1.376 0 0 1 .5 8.31V3.69c0-.493.269-.949.706-1.195L5.294.185a1.438 1.438 0 0 1 1.412 0z"/></svg>',
          high: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><path fill="#dd2b0e" d="M6.713.295l4.992 4.992a1.008 1.008 0 0 1 0 1.426l-4.992 4.992a1.008 1.008 0 0 1-1.426 0L.295 6.713a1.008 1.008 0 0 1 0-1.426L5.287.295a1.008 1.008 0 0 1 1.426 0z"/></svg>',
          medium: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><path fill="#fc9403" d="M5.04 10.454L.24 3.182c-.398-.603-.29-1.457.24-1.91C.688 1.097.94 1 1.2 1h9.6c.663 0 1.2.61 1.2 1.364 0 .295-.084.582-.24.818l-4.8 7.272c-.398.603-1.15.725-1.68.273a1.295 1.295 0 0 1-.24-.273z"/></svg>',
          low: '<svg width="14" height="14" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg"><path d="m6.85,12.6a6.05,5.8 0 1 1 0,-11.6a6.05,5.8 0 0 1 0,11.6z" fill="#fc9403" id="severity_low"/></svg>',
          info: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><path fill="#428fdc" d="M8 16A8 8 0 1 1 8 0a8 8 0 0 1 0 16zm.75-12.25a.75.75 0 1 0-1.5 0 .75.75 0 0 0 1.5 0zM8 5.25a.75.75 0 0 0-.75.75v4.5a.75.75 0 1 0 1.5 0V6A.75.75 0 0 0 8 5.25z"/></svg>',
          unknown: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><path fill="#868686" d="M8 16A8 8 0 1 1 8 0a8 8 0 0 1 0 16zM4.927 4.99c-.285.429-.427.853-.427 1.27 0 .203.09.392.27.566.18.174.4.26.661.26.443 0 .744-.248.903-.746.168-.475.373-.835.616-1.08.243-.244.62-.366 1.134-.366.439 0 .797.12 1.075.363.277.242.416.54.416.892a.97.97 0 0 1-.136.502 1.91 1.91 0 0 1-.336.419 14.35 14.35 0 0 1-.648.558c-.34.282-.611.525-.812.73-.2.205-.362.443-.483.713-.322 1.245 1.35 1.345 1.736.456.047-.086.118-.18.213-.284.096-.103.223-.223.382-.36a41.14 41.14 0 0 0 1.194-1.034c.221-.204.412-.448.573-.73a1.95 1.95 0 0 0 .242-.984c0-.475-.141-.915-.424-1.32-.282-.406-.682-.726-1.2-.962-.518-.235-1.115-.353-1.792-.353-.728 0-1.365.14-1.911.423-.546.282-.961.637-1.246 1.066zm2.14 7.08a1 1 0 1 0 2 0 1 1 0 0 0-2 0z"/></svg>'
        }.freeze
        # rubocop:enable  Layout/LineLength

        def self.render(pdf, data: {})
          new(pdf, data).render
        end

        def initialize(pdf, data)
          @pdf = pdf
          @charts = process_raw(data)
          @selected_day_range = data&.dig(:selected_day_range)
          @date_info = data&.dig(:date_info)
          @width = 500
          @height = 400
          @icon_size = 14
          @y = pdf.cursor
        end

        def render
          return :noop if @charts.blank?

          @pdf.bounding_box([0, @y], width: @pdf.bounds.right, height: @height) do
            # Background
            @pdf.save_graphics_state
            @pdf.fill_color "F9F9F9"
            @pdf.fill_rectangle [0, @pdf.bounds.top], @pdf.bounds.right, @height
            @pdf.restore_graphics_state

            # Title
            @pdf.text_box(
              s_('Vulnerability History'),
              at: [0, @pdf.bounds.top - 10],
              width: @pdf.bounds.right,
              align: :center,
              style: :bold,
              size: 16
            )

            # Date information
            @pdf.text_box(
              "#{@date_info} (#{@selected_day_range})",
              at: [0, @pdf.bounds.top - 40],
              width: @pdf.bounds.right,
              align: :center,
              size: 12
            )

            # the info table
            draw_table_header
            @charts.each_with_index do |chart, index|
              draw_chart_row(chart, index)
            end
          end
        end

        private

        def draw_table_header
          @pdf.save_graphics_state
          y_position = @pdf.bounds.top - 80

          @pdf.bounding_box([10, y_position - 5], width: 100, height: 20) do
            @pdf.text "Severity", style: :bold, size: 12
          end

          @pdf.bounding_box([@pdf.bounds.right - 150, y_position - 5], width: 50, height: 20) do
            @pdf.text "%", style: :bold, size: 12, align: :center
          end

          @pdf.bounding_box([@pdf.bounds.right - 80, y_position - 5], width: 50, height: 20) do
            @pdf.text "#", style: :bold, size: 12, align: :center
          end

          @pdf.stroke_color "000000"
          @pdf.stroke_horizontal_line 0, @pdf.bounds.right, at: y_position - 25

          @chart_start_position = y_position - 35
          @pdf.restore_graphics_state
        end

        def draw_chart_row(chart, index)
          row_height = 70
          y_position = @chart_start_position - (index * row_height)

          icon_svg = SEVERITY_ICONS[chart[:severity].to_sym]
          @pdf.svg(icon_svg, at: [10, @pdf.cursor - 25], width: @icon_size, height: @icon_size)

          @pdf.text_box(
            chart[:severity],
            at: [30, @pdf.cursor + 12],
            width: 100
          )

          svg_width = @pdf.bounds.right * 0.5
          @pdf.svg chart[:svg], at: [100, y_position - 15], width: svg_width, height: 70

          @pdf.text_box(
            chart[:change_in_percent],
            at: [@pdf.bounds.right - 150, y_position - 15],
            width: 50,
            height: 20,
            align: :center,
            style: :bold,
            size: 12
          )

          @pdf.text_box(
            chart[:current_count].to_s,
            at: [@pdf.bounds.right - 80, y_position - 15],
            width: 50,
            height: 20,
            align: :center,
            style: :bold,
            size: 12
          )
        end

        def process_raw(data)
          charts = data.present? ? data[:charts] : []
          return if charts.blank?

          charts.each do |chart|
            svg = CGI.unescape(chart[:svg]).delete!("\n")[%r{(<svg.*</svg>)}, 1]
            chart[:svg] = svg
          end

          charts
        end
      end
    end
  end
end
