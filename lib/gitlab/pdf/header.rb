# frozen_string_literal: true

require "prawn"
require "prawn-svg"

module Gitlab
  module PDF
    class Header
      include Prawn::View

      def self.render(pdf, exportable_title, page: 0, height: 50)
        new(pdf, page, height, exportable_title).render
      end

      def initialize(pdf, page, height, exportable_title)
        @pdf = pdf
        @page = page
        @height = height
        @halfway_point = pdf.bounds.width / 2
        @exportable_title = exportable_title
      end

      def render
        y = @pdf.bounds.top
        @pdf.bounding_box([0, y], width: @pdf.bounds.right, height: @height) do
          # The logo and GitLab text
          @pdf.bounding_box([0, @pdf.bounds.top], width: @halfway_point, height: @height) do
            logo_path = Rails.root.join('app/assets/images/gitlab_logo.png')

            @pdf.image(
              logo_path,
              width: 21,
              height: 21,
              position: :left,
              vposition: 6
            )

            @pdf.text_box(
              "GitLab",
              at: [25, @pdf.bounds.top],
              width: 100,
              height: 30,
              valign: :center,
              size: 24,
              style: :bold
            )
          end

          # Title (right side)
          @pdf.bounding_box([@halfway_point, @pdf.bounds.top], width: @halfway_point, height: @height) do
            @exportable_title ||= "Vulnerability Summary"

            @pdf.text_box(
              "#{@exportable_title} | #{Date.current.strftime('%B %-d, %Y')} | #{@page}",
              align: :right,
              valign: :center,
              size: 10
            )
          end

          # Gradient bar using SVG
          gradient_svg = <<~SVG
          <svg width="#{@pdf.bounds.width}" height="10">
            <defs>
              <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="0%">
                <stop offset="0%" style="stop-color:#d2afed;stop-opacity:1" />
                <stop offset="25%" style="stop-color:#fa8bca;stop-opacity:1" />
                <stop offset="50%" style="stop-color:#ff76a4;stop-opacity:1" />
                <stop offset="100%" style="stop-color:#fd6c30;stop-opacity:1" />
              </linearGradient>
            </defs>
            <rect width="100%" height="10" fill="url(#grad)"/>
          </svg>
          SVG

          # Position the gradient bar just below the header content
          @pdf.svg gradient_svg, at: [0, @pdf.bounds.top - 45]
        end
      end
    end
  end
end
