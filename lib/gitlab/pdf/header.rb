# frozen_string_literal: true

require "prawn"
require "prawn-svg"

module Gitlab
  module PDF
    class Header
      include Prawn::View

      HEADER_HEIGHT = 50
      LOGO_SIZE = 21
      LOGO_VPOSITION = 6
      GITLAB_TEXT_X_OFFSET = 25
      GITLAB_TEXT_WIDTH = 100
      GITLAB_TEXT_HEIGHT = 30
      GITLAB_TEXT_FONT_SIZE = 24
      METADATA_FONT_SIZE = 8
      METADATA_COLOR = "888888"
      GRADIENT_BAR_HEIGHT = 10
      GRADIENT_BAR_Y_OFFSET = 45

      def self.render(pdf, exportable, page: 0, height: HEADER_HEIGHT)
        new(pdf, page, height, exportable).render
      end

      def initialize(pdf, page, height, exportable)
        @pdf = pdf
        @page = page
        @height = height
        @halfway_point = pdf.bounds.width / 2
        @exportable = exportable
      end

      def render
        y = @pdf.bounds.top
        @pdf.bounding_box([0, y], width: @pdf.bounds.right, height: @height) do
          # The logo and GitLab text
          @pdf.bounding_box([0, @pdf.bounds.top], width: @halfway_point, height: @height) do
            logo_path = Rails.root.join('app/assets/images/gitlab_logo.png')

            begin
              @pdf.image(logo_path, width: LOGO_SIZE, height: LOGO_SIZE, position: :left, vposition: LOGO_VPOSITION)
            rescue ArgumentError
              nil
            end

            @pdf.text_box(
              "GitLab",
              at: [GITLAB_TEXT_X_OFFSET, @pdf.bounds.top],
              width: GITLAB_TEXT_WIDTH,
              height: GITLAB_TEXT_HEIGHT,
              valign: :center,
              size: GITLAB_TEXT_FONT_SIZE,
              style: :bold
            )
          end

          # Title (right side)
          @pdf.bounding_box([@halfway_point, @pdf.bounds.top], width: @halfway_point, height: @height) do
            label = @exportable.is_a?(Group) ? "Group" : "Project"

            @pdf.formatted_text_box(
              [
                { text: "#{label}: ", size: METADATA_FONT_SIZE, color: METADATA_COLOR },
                { text: @exportable.name, styles: [:bold], size: METADATA_FONT_SIZE },
                { text: " | #{Date.current.strftime('%B %-d, %Y')} | #{@page}",
                  size: METADATA_FONT_SIZE, color: METADATA_COLOR }
              ],
              at: [0, @pdf.bounds.top],
              width: @halfway_point,
              height: @height,
              align: :right,
              valign: :center
            )
          end

          # Gradient bar using SVG
          gradient_svg = <<~SVG
          <svg width="#{@pdf.bounds.width}" height="#{GRADIENT_BAR_HEIGHT}">
            <defs>
              <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="0%">
                <stop offset="0%" style="stop-color:#d2afed;stop-opacity:1" />
                <stop offset="25%" style="stop-color:#fa8bca;stop-opacity:1" />
                <stop offset="50%" style="stop-color:#ff76a4;stop-opacity:1" />
                <stop offset="100%" style="stop-color:#fd6c30;stop-opacity:1" />
              </linearGradient>
            </defs>
            <rect width="100%" height="#{GRADIENT_BAR_HEIGHT}" fill="url(#grad)"/>
          </svg>
          SVG

          # Position the gradient bar just below the header content
          @pdf.svg gradient_svg, at: [0, @pdf.bounds.top - GRADIENT_BAR_Y_OFFSET]
        end
      end
    end
  end
end
