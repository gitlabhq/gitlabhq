# frozen_string_literal: true

module Layouts
  class SettingsBlockComponent < ViewComponent::Base
    # @param [String] heading
    # @param [String] description
    # @param [String] id
    # @param [Boolean] expanded
    def initialize(heading, description: nil, id: nil, expanded: nil)
      @heading = heading
      @description = description
      @id = id
      @expanded = expanded
    end

    renders_one :heading
    renders_one :description
    renders_one :body

    private

    def section_classes
      classes = %w[settings no-animate]
      classes.push('expanded') if @expanded
      classes.join(' ')
    end

    def title_classes
      %w[gl-heading-2 gl-cursor-pointer !gl-mb-2 js-settings-toggle js-settings-toggle-trigger-only]
    end

    def button_text
      @expanded ? _('Collapse') : _('Expand')
    end

    def js_id
      @id ? "js-#{@id}" : nil
    end
  end
end
