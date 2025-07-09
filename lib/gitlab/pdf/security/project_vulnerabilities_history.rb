# frozen_string_literal: true

require "prawn"
require "prawn-svg"

module Gitlab
  module PDF
    module Security
      class ProjectVulnerabilitiesHistory
        include Prawn::View

        SEVERITY_LEGEND = [
          { name: "Critical", color: "660e00" },
          { name: "High",     color: "ae1800" },
          { name: "Medium",   color: "9e5400" },
          { name: "Low",      color: "c17d10" },
          { name: "Info",     color: "428fdc" },
          { name: "Unknown",  color: "868686" }
        ].freeze

        # the SVG provided by the frontend uses CSS variables, but
        # prawn-svg does not support CSS variables. We will gsub in
        # hardedcoded colors for the CSS variable we care about.
        CSS_TRANSLATIONS = [
          ['var(--gl-chart-axis-line-color)', '#dddddd'],
          ['var(--gl-text-color-default)', '#333333'],
          ['var(--gl-chart-axis-text-color)', '#666666']
        ].freeze

        def self.render(pdf, data: nil)
          new(pdf, data).render
        end

        def initialize(pdf, data)
          @pdf = pdf
          @data = process_raw(data)
          @height = 250
          @svg_height = 200
          @y = pdf.cursor
        end

        # rubocop:disable Metrics/AbcSize --- this is the nature of the dsl.
        def render
          return :noop if @data.blank?

          @pdf.bounding_box([0, @y], width: @pdf.bounds.right, height: @height) do
            # draw the slightly off-white background
            @pdf.save_graphics_state
            @pdf.fill_color "F9F9F9"
            @pdf.fill_rectangle [0 - 10, @pdf.bounds.top], @pdf.bounds.right + 10, @height
            @pdf.restore_graphics_state

            @pdf.move_down 10

            # rubocop:disable Layout/LineLength -- long text for title
            # draw the title
            @pdf.text_box(
              s_('Vulnerability History'),
              at: [0, @pdf.cursor],
              width: @pdf.bounds.right, height: 20,
              align: :left, style: :bold, size: 14)

            @pdf.move_down 20

            @pdf.text_box(
              s_("Historical view of open vulnerabilities in the default branch. Excludes vulnerabilities that were resolved or dismissed."),
              at: [0, @pdf.cursor],
              width: @pdf.bounds.right, height: 20,
              align: :left, size: 10)
            # rubocop:enable  Layout/LineLength

            @pdf.move_down 10

            @pdf.bounding_box([0, @pdf.cursor], width: @pdf.bounds.right, height: @height - 40) do
              # SVG from the frontend
              @pdf.svg @data, width: @pdf.bounds.right, height: @svg_height

              @pdf.move_down 20
              legend_y = @pdf.cursor

              # draw a divider line
              @pdf.save_graphics_state
              @pdf.stroke_color "dddddd"
              @pdf.stroke_line([0, legend_y + 20], [@pdf.bounds.right, legend_y + 20])
              @pdf.restore_graphics_state

              # draw the SVG chart's legend
              legend_line_width = 8
              legend_line_right_padding = 5
              legend_item_width = legend_line_width + legend_line_right_padding + 40
              start_x = @pdf.bounds.left + 30

              SEVERITY_LEGEND.each_with_index do |severity, index|
                x_position = start_x + (index * legend_item_width)

                @pdf.save_graphics_state
                @pdf.stroke_color severity[:color]
                @pdf.line_width = 2
                @pdf.stroke_line([x_position, legend_y], [x_position + legend_line_width, legend_y])

                @pdf.fill_color '000000'
                x_position += legend_line_width + legend_line_right_padding

                @pdf.text_box(
                  severity[:name],
                  at: [x_position, legend_y + 7],
                  width: legend_item_width, height: 15,
                  valign: :center, style: :bold, size: 8)
                @pdf.restore_graphics_state
              end
            end
          end
        end
        # rubocop:enable Metrics/AbcSize

        private

        def process_raw(data)
          return if data.blank?

          svg = CGI.unescape(data).delete!("\n")[%r{(<svg.*</svg>)}, 1]
          CSS_TRANSLATIONS.each { |css_variable, color| svg.gsub!(css_variable, color) }

          svg
        end
      end
    end
  end
end
