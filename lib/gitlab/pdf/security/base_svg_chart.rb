# frozen_string_literal: true

require "prawn"
require "prawn-svg"

module Gitlab
  module PDF
    module Security
      class BaseSvgChart
        include Prawn::View

        PADDING = 10
        SPACING = 20
        TITLE_HEIGHT = 20
        TITLE_FONT_SIZE = 14
        DESCRIPTION_HEIGHT = 20
        DESCRIPTION_FONT_SIZE = 10
        BACKGROUND_COLOR = "F9F9F9"

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

          @pdf.bounding_box([0, @y], width: @pdf.bounds.right, height: total_height) do
            draw_background

            @pdf.move_down PADDING

            @pdf.bounding_box([PADDING, @pdf.cursor],
              width: @pdf.bounds.right - (PADDING * 2),
              height: total_height) do
              draw_title
              draw_description

              available_width = @pdf.bounds.right

              @pdf.move_down SPACING

              available_height = @pdf.cursor - @pdf.bounds.bottom
              draw_svg(available_width, available_height)
            end
          end
        end

        private

        def total_height
          raise NotImplementedError, "#{self.class} must implement #total_height"
        end

        def title_text
          raise NotImplementedError, "#{self.class} must implement #title_text"
        end

        def description_text
          raise NotImplementedError, "#{self.class} must implement #description_text"
        end

        def css_translations
          []
        end

        def draw_background
          @pdf.save_graphics_state
          @pdf.fill_color BACKGROUND_COLOR
          @pdf.fill_rectangle [0, @pdf.bounds.top], @pdf.bounds.right, total_height
          @pdf.restore_graphics_state
        end

        def draw_title
          @pdf.text_box(
            title_text,
            at: [0, @pdf.cursor],
            width: @pdf.bounds.right,
            height: TITLE_HEIGHT,
            align: :left,
            style: :bold,
            size: TITLE_FONT_SIZE
          )
          @pdf.move_down SPACING
        end

        def draw_description
          @pdf.text_box(
            description_text,
            at: [0, @pdf.cursor],
            width: @pdf.bounds.right,
            height: DESCRIPTION_HEIGHT,
            align: :left,
            size: DESCRIPTION_FONT_SIZE
          )
          @pdf.move_down SPACING
        end

        # The SVG dimensions from the frontend vary with the user's screen resolution
        # We use the aspect ratio to fit it within the available space without distortion.
        def draw_svg(available_width, available_height)
          ratio = svg_aspect_ratio

          if ratio && ratio > 0 && available_height > 0
            height_if_width_constrained = available_width / ratio

            if height_if_width_constrained <= available_height
              @pdf.svg @data, width: available_width, position: :center
            else
              @pdf.svg @data, height: available_height, position: :center
            end
          else
            @pdf.svg @data, width: available_width, position: :center
          end
        end

        def svg_aspect_ratio
          svg_width = @data[/<svg\b[^>]*?\bwidth="(\d+(?:\.\d+)?)"/i, 1]&.to_f
          svg_height = @data[/<svg\b[^>]*?\bheight="(\d+(?:\.\d+)?)"/i, 1]&.to_f

          return if svg_width.nil? || svg_height.nil? || svg_height == 0

          svg_width / svg_height
        end

        def process_raw(data)
          return if data.blank?

          svg = if data.is_a?(Hash)
                  data['svg'] || data[:svg]
                else
                  data
                end

          return if svg.blank?

          svg = CGI.unescape(svg)[%r{(<svg.*?</svg>)}m, 1]

          return if svg.blank?

          css_translations.each { |css_variable, color| svg.gsub!(css_variable, color) }

          svg
        end
      end
    end
  end
end
