# frozen_string_literal: true
module Pajamas
  class AlertComponentPreview < ViewComponent::Preview
    # @param title text
    # @param body text
    # @param dismissible toggle
    # @param variant select [info, warning, success, danger, tip]
    def default(title: "Alert title (optional)", body: "Alert message goes here.", dismissible: true, variant: :info)
      render(Pajamas::AlertComponent.new(
               title: title,
               dismissible: dismissible,
               variant: variant.to_sym
             )) do |c|
        if body
          c.with_body { body }
        end
      end
    end
  end
end
