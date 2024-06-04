# frozen_string_literal: true

module Layouts
  class PageHeadingComponentPreview < ViewComponent::Preview
    # @param heading text
    # @param actions text
    def default(
      heading: 'Page heading',
      actions: 'Page actions go here'
    )
      render(::Layouts::PageHeadingComponent.new(heading)) do |c|
        c.with_actions { actions }
      end
    end
  end
end
