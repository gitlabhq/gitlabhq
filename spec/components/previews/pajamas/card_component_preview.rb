# frozen_string_literal: true

module Pajamas
  class CardComponentPreview < ViewComponent::Preview
    COLLECTION = [
      {
        header: 'header',
        body: 'Every card has a body',
        footer: 'footer'
      },
      {
        header: 'second header',
        body: 'second body',
        footer: 'second footer'
      }
    ].freeze

    # Card
    # ----
    # See its design reference [here](https://design.gitlab.com/components/card).
    #
    # @param header text
    # @param body textarea
    # @param footer text
    def default(header: nil, body: "Every card has a body.", footer: nil)
      render(Pajamas::CardComponent.new) do |c|
        c.with_header { header } if header

        c.with_body do
          content_tag(:p, body)
        end

        c.with_footer { footer } if footer
      end
    end

    # @param collection [Array] "collection of cards as an array of hashes with header, body, footer"
    def with_collection(collection: COLLECTION)
      render(Pajamas::CardComponent.with_collection(collection, card_options: { class: 'gl-mb-5' }))
    end
  end
end
