# frozen_string_literal: true

module Layouts
  class SettingsSectionComponentPreview < ViewComponent::Preview
    # @param heading text
    # @param description text
    # @param body text
    # @param id text
    # @param testid text
    # @param options
    def default(
      heading: 'Settings section heading',
      description: 'Settings section description',
      body: 'Settings section content',
      id: 'settings-section-id',
      testid: 'settings-section-testid',
      options: { data: { test: 'value' } }
    )
      render(::Layouts::SettingsSectionComponent.new(
        heading, description: description,
        id: id, testid: testid, options: options
      )) do |c|
        c.with_description { description }
        c.with_body { body }
      end
    end
  end
end
