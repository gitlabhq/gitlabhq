# frozen_string_literal: true

module Layouts
  class HorizontalSectionComponentPreview < ViewComponent::Preview
    # @param border toggle
    # @param title text
    # @param description text
    # @param body text
    def default(
      border: true,
      title: 'Naming, visibility',
      description: 'Update your group name, description, avatar, and visibility.',
      body: 'Settings fields here.'
    )
      render(::Layouts::HorizontalSectionComponent.new(border: border, options: { class: 'gl-mb-6 gl-pb-3' })) do |c|
        c.with_title { title }
        c.with_description { description }
        c.with_body { body }
      end
    end
  end
end
