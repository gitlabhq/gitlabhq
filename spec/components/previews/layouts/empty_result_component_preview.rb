# frozen_string_literal: true

module Layouts
  class EmptyResultComponentPreview < ViewComponent::Preview
    # @param type select {{ Layouts::EmptyResultComponent::TYPE_OPTIONS }}

    def default(type: :search)
      render(::Layouts::EmptyResultComponent.new(
        type: type
      ))
    end
  end
end
