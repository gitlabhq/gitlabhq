# frozen_string_literal: true

module Pajamas
  class AccordionComponentPreview < ViewComponent::Preview
    # @param title text
    # @param body text
    # @param state
    def default(title: "Accordion title (open)", body: "Accordion body", state: :opened)
      render(Pajamas::AccordionComponent.new(
        title: title,
        body: body,
        state: state
      ))
    end

    def closed(title: "Accordion title (closed)", body: "Accordion body", state: :closed)
      render(Pajamas::AccordionComponent.new(
        title: title,
        body: body,
        state: state
      ))
    end
  end
end
