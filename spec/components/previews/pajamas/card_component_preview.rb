# frozen_string_literal: true
module Pajamas
  class CardComponentPreview < ViewComponent::Preview
    # Card
    # ----
    # See its design reference [here](https://design.gitlab.com/components/card).
    #
    # @param header text
    # @param body textarea
    # @param footer text
    def default(header: nil, body: "Every card has a body.", footer: nil)
      render(Pajamas::CardComponent.new) do |c|
        if header
          c.with_header { header }
        end

        c.with_body do
          content_tag(:p, body)
        end

        if footer
          c.with_footer { footer }
        end
      end
    end
  end
end
