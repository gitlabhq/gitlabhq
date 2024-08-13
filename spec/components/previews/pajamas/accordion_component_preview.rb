# frozen_string_literal: true

module Pajamas
  class AccordionComponentPreview < ViewComponent::Preview
    # @param title text
    # @param state
    def default(title: "Accordion title (open)", state: :opened)
      render(Pajamas::AccordionItemComponent.new(
        title: title,
        state: state
      ))
    end

    def closed(title: "Accordion title (closed)", state: :closed)
      render(Pajamas::AccordionItemComponent.new(
        title: title,
        state: state
      ))
    end
  end
end
