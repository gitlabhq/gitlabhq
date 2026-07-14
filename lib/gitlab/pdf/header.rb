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
      ICON_SIZE = METADATA_FONT_SIZE + 2
      ICON_PADDING = 4

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
          render_left_section
          render_right_section
          render_gradient_bar
        end
      end

      private

      def render_left_section
        @pdf.bounding_box([0, @pdf.bounds.top], width: @halfway_point, height: @height) do
          render_gitlab_logo
          render_gitlab_name
        end
      end

      def render_right_section
        @pdf.bounding_box([@halfway_point, @pdf.bounds.top], width: @halfway_point, height: @height) do
          label = exportable_label
          icon_path = local_avatar_path
          icon_width = icon_path ? ICON_SIZE + ICON_PADDING : 0
          text_width = metadata_text_width(label, icon_width)

          # Anchor the icon+text group to the right edge of the section
          group_x = @halfway_point - icon_width - text_width

          if icon_path && !render_exportable_logo(icon_path, group_x)
            group_x += icon_width
            icon_width = 0
          end

          text_x = group_x + icon_width
          render_exportable_metadata(label, text_x, @halfway_point - text_x)
        end
      end

      def render_exportable_logo(icon_path, x_pos)
        @pdf.image(icon_path, width: ICON_SIZE, height: ICON_SIZE,
          at: [x_pos, @pdf.bounds.top - ((@height - ICON_SIZE) / 2)])
        true
      rescue StandardError => e
        Gitlab::AppLogger.warn(message: "PDF header: failed to render exportable avatar", error: e.message)
        false
      end

      def render_gitlab_logo
        logo_path = Rails.root.join('app/assets/images/gitlab_logo.png')
        @pdf.image(logo_path, width: LOGO_SIZE, height: LOGO_SIZE, position: :left, vposition: LOGO_VPOSITION)
      rescue ArgumentError
        nil
      end

      def render_gitlab_name
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

      def render_exportable_metadata(label, x_pos, width)
        @pdf.formatted_text_box(
          [
            { text: "#{label}: ", size: METADATA_FONT_SIZE, color: METADATA_COLOR },
            { text: @exportable.name, styles: [:bold], size: METADATA_FONT_SIZE },
            { text: " | #{Date.current.strftime('%B %-d, %Y')} | #{@page}",
              size: METADATA_FONT_SIZE, color: METADATA_COLOR }
          ],
          at: [x_pos, @pdf.bounds.top],
          width: width,
          height: @height,
          align: :right,
          valign: :center
        )
      end

      def render_gradient_bar
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

        @pdf.svg gradient_svg, at: [0, @pdf.bounds.top - GRADIENT_BAR_Y_OFFSET]
      end

      def exportable_label
        @exportable.is_a?(Group) ? "Group" : "Project"
      end

      def metadata_text_width(label, icon_width)
        normal = "#{label}: " + " | #{Date.current.strftime('%B %-d, %Y')} | #{@page}"
        normal_width = @pdf.width_of(normal, size: METADATA_FONT_SIZE)
        bold_width = @pdf.width_of(@exportable.name, size: METADATA_FONT_SIZE, style: :bold)
        [@halfway_point - icon_width, normal_width + bold_width].min
      end

      def local_avatar_path
        uploader = @exportable.avatar
        return unless uploader.file_storage? && uploader.file.present?

        uploader.file.path
      end
    end
  end
end
