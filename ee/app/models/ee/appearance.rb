module EE
  module Appearance
    extend ActiveSupport::Concern

    prepended do
      cache_markdown_field :header_message
      cache_markdown_field :footer_message

      validates :background_color, allow_blank: true, color: true
      validates :font_color,  allow_blank: true, color: true

      default_value_for :background_color, '#E75E40'
      default_value_for :font_color,  '#FFFFFF'
    end
  end
end
