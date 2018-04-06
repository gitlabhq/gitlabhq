module EE
  module Appearance
    extend ActiveSupport::Concern

    prepended do
      cache_markdown_field :header_message, pipeline: :broadcast_message
      cache_markdown_field :footer_message, pipeline: :broadcast_message

      validates :message_background_color, allow_blank: true, color: true
      validates :message_font_color,  allow_blank: true, color: true

      default_value_for :message_background_color, '#E75E40'
      default_value_for :message_font_color,  '#FFFFFF'
    end

    def show_header?
      header_message.present?
    end

    def show_footer?
      footer_message.present?
    end
  end
end
