# frozen_string_literal: true

module Layouts
  class PageHeadingComponentPreview < ViewComponent::Preview
    # @param heading text
    # @param actions text
    # @param description text
    def default(
      heading: 'Page heading',
      actions: 'Page actions go here',
      description: 'Page description goes here'
    )
      render(::Layouts::PageHeadingComponent.new(heading)) do |c|
        c.with_actions { actions }
        c.with_description { description }
      end
    end
  end
end
