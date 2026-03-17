# frozen_string_literal: true

require "prawn"
require "prawn-svg"

module Gitlab
  module PDF
    module Security
      class TotalRiskScore
        include Prawn::View

        # the SVG provided by the frontend uses CSS variables, but
        # prawn-svg does not support CSS variables. We will gsub in
        # hardcoded colors for the CSS variables we care about.
        CSS_TRANSLATIONS = [
          ['var(--gl-chart-axis-line-color)', '#dddddd'],
          ['var(--gl-text-color-default)', '#333333'],
          ['var(--gl-chart-axis-text-color)', '#666666'],
          ['var(--risk-score-color-low)', '#16a34a'],
          ['var(--risk-score-color-medium)', '#f97316'],
          ['var(--risk-score-color-high)', '#ea580c'],
          ['var(--risk-score-color-critical)', '#b91c1c'],
          ['var(--risk-score-gauge-text-low)', '#16a34a'],
          ['var(--risk-score-gauge-text-medium)', '#f97316'],
          ['var(--risk-score-gauge-text-high)', '#ea580c'],
          ['var(--risk-score-gauge-text-critical)', '#b91c1c']
        ].freeze

        PADDING = 10
        TOTAL_HEIGHT = 300

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

            @pdf.bounding_box([PADDING, @pdf.cursor],
              width: @pdf.bounds.right - (PADDING * 2),
              height: TOTAL_HEIGHT) do
              draw_title
              draw_description

              remaining_height = @pdf.cursor - @pdf.bounds.bottom

              draw_svg(remaining_height)
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
            s_('Total Risk Score'),
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
            s_("The overall risk score for your organization based on vulnerability severity and age."),
            at: [0, @pdf.cursor],
            width: @pdf.bounds.right,
            height: 20,
            align: :left,
            size: 10
          )
          @pdf.move_down 10
        end

        def draw_svg(height)
          @pdf.svg @data,
            height: height,
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

          CSS_TRANSLATIONS.each { |css_variable, color| svg.gsub!(css_variable, color) }

          svg
        end
      end
    end
  end
end
