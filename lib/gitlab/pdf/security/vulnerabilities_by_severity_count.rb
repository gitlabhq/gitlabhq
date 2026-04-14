# frozen_string_literal: true

module Gitlab
  module PDF
    module Security
      class VulnerabilitiesBySeverityCount
        include Prawn::View

        GAP = 6
        PADDING = 8
        TITLE_HEIGHT = 16
        TITLE_FONT_SIZE = 12
        COUNT_HEIGHT = 36
        MEDIAN_HEIGHT = 14
        HEIGHT = (PADDING * 2) + TITLE_HEIGHT + COUNT_HEIGHT + MEDIAN_HEIGHT
        BACKGROUND_COLOR = "F9F9F9"
        DEFAULT_FONT_COLOR = "000000"
        BORDER_RADIUS = 4
        CIRCLE_RADIUS = 4
        CIRCLE_GAP = 4
        SEVERITIES = [:critical, :high, :medium, :low, :info, :unknown].freeze
        FALLBACK_SEVERITY_COLORS = {
          critical: "AA1100",
          high: "C0622A",
          medium: "C17D10",
          low: "0070CC",
          info: "1068BF",
          unknown: "999999"
        }.freeze

        def self.render(pdf, data: nil)
          new(pdf, data).render
        end

        def initialize(pdf, data)
          @pdf = pdf
          @data = data || {}
          @y = pdf.cursor
        end

        def render
          SEVERITIES.each_with_index do |severity, index|
            severity_data = @data[severity] || { count: 0, medianAge: nil, color: FALLBACK_SEVERITY_COLORS[severity] }
            x_offset = index * severity_box_width

            draw_severity_box(x_offset, severity, severity_data)
          end
        end

        private

        def draw_severity_box(x_offset, severity, severity_data)
          @pdf.bounding_box([x_offset + (GAP / 2), @y], width: severity_box_width - GAP, height: HEIGHT) do
            @pdf.fill_color BACKGROUND_COLOR
            @pdf.fill_rounded_rectangle(
              [@pdf.bounds.left, @pdf.bounds.top],
              @pdf.bounds.width,
              HEIGHT,
              BORDER_RADIUS
            )
            @pdf.fill_color DEFAULT_FONT_COLOR

            @pdf.bounding_box(
              [@pdf.bounds.left + PADDING, @pdf.bounds.top - PADDING],
              width: @pdf.bounds.width - (PADDING * 2),
              height: HEIGHT - (PADDING * 2)
            ) do
              draw_title(severity, severity_data)
              draw_count(severity_data)
              draw_median_age(severity_data) if display_median_age?(severity_data)
            end
          end
        end

        def draw_severity_circle(severity, severity_data)
          circle_x = @pdf.bounds.left + CIRCLE_RADIUS
          circle_y = @pdf.cursor - (TITLE_FONT_SIZE / 2.0) + 2
          @pdf.fill_color severity_color(severity, severity_data)
          @pdf.fill_circle [circle_x, circle_y], CIRCLE_RADIUS
          # Reset fill color since Prawn uses it globally for both shapes and text
          @pdf.fill_color DEFAULT_FONT_COLOR
        end

        def draw_title(severity, severity_data)
          draw_severity_circle(severity, severity_data)

          text_x = @pdf.bounds.left + (CIRCLE_RADIUS * 2) + CIRCLE_GAP
          text_width = @pdf.bounds.width - (CIRCLE_RADIUS * 2) - CIRCLE_GAP
          @pdf.text_box severity.to_s.capitalize,
            at: [text_x, @pdf.cursor],
            width: text_width,
            height: TITLE_HEIGHT,
            size: TITLE_FONT_SIZE,
            style: :bold,
            overflow: :shrink_to_fit,
            single_line: true
          @pdf.move_down TITLE_HEIGHT
        end

        def draw_count(severity_data)
          @pdf.text_box severity_count(severity_data),
            at: [@pdf.bounds.left, @pdf.cursor],
            width: @pdf.bounds.width,
            height: COUNT_HEIGHT,
            size: 24,
            style: :bold,
            overflow: :shrink_to_fit,
            single_line: true
          @pdf.move_down COUNT_HEIGHT
        end

        def draw_median_age(severity_data)
          @pdf.text_box median_age_text(severity_data),
            at: [@pdf.bounds.left, @pdf.cursor],
            width: @pdf.bounds.width,
            height: MEDIAN_HEIGHT,
            size: 10,
            overflow: :shrink_to_fit,
            single_line: true
          @pdf.move_down MEDIAN_HEIGHT
        end

        def severity_box_width
          @pdf.bounds.width / SEVERITIES.size
        end

        def display_median_age?(severity_data)
          severity_data[:count] &&
            severity_data[:count] > 0 &&
            severity_data[:medianAge].present?
        end

        def severity_count(severity_data)
          (severity_data[:count] || 0).to_s
        end

        def median_age_text(severity_data)
          median_age = if severity_data[:medianAge].instance_of?(String)
                         severity_data[:medianAge].to_f
                       else
                         severity_data[:medianAge]
                       end

          "Median: #{median_age.ceil} days"
        end

        def severity_color(severity, severity_data)
          color = severity_data[:color] || FALLBACK_SEVERITY_COLORS[severity]
          color.to_s.delete_prefix("#")
        end
      end
    end
  end
end
