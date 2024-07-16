# frozen_string_literal: true

module Layouts
  class SettingsBlockComponentPreview < ViewComponent::Preview
    # @param heading text
    # @param description text
    # @param body text
    # @param id text
    def default(
      heading: 'Settings block heading',
      description: 'Settings block description',
      body: 'Settings block content',
      id: 'settings-block-id'
    )
      render(::Layouts::SettingsBlockComponent.new(heading, description: description, id: id, expanded: nil)) do |c|
        c.with_description { description }
        c.with_body { body }
      end
    end
  end
end
