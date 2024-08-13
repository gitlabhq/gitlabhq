# frozen_string_literal: true

# Renders a GlCard root element
module Pajamas
  class CardComponent < Pajamas::Component
    # @param [Hash] card_options
    # @param [Hash] header_options
    # @param [Hash] body_options
    # @param [Hash] footer_options
    # @card [Hash] card structure as an object. This enables .with_collection functionality.
    def initialize(card: {}, card_options: {}, header_options: {}, body_options: {}, footer_options: {})
      @card_options = card_options
      @header_options = header_options
      @body_options = body_options
      @footer_options = footer_options
      @card = card
    end

    renders_one :header
    renders_one :body
    renders_one :footer

    private

    attr_reader :card

    def parsed_header?
      header? || card[:header].present?
    end

    def parsed_header
      header || card[:header]
    end

    def parsed_body
      body || card[:body]
    end

    def parsed_footer?
      footer? || card[:footer].present?
    end

    def parsed_footer
      footer || card[:footer]
    end
  end
end
