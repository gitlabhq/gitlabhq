# frozen_string_literal: true

# Renders a GlCard root element
module Pajamas
  class CardComponent < Pajamas::Component
    # @param [Hash] card_options
    # @param [Hash] header_options
    # @param [Hash] body_options
    # @param [Hash] footer_options
    def initialize(card_options: {}, header_options: {}, body_options: {}, footer_options: {})
      @card_options = card_options
      @header_options = header_options
      @body_options = body_options
      @footer_options = footer_options
    end

    renders_one :header
    renders_one :body
    renders_one :footer
  end
end
