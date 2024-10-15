# frozen_string_literal: true

module Layouts
  class SettingsBlockComponent < ViewComponent::Base
    # @param [String] heading
    # @param [String] description
    # @param [String] id
    # @param [String] testid
    # @param [Boolean] expanded
    # @param [Hash] button_options
    def initialize(
      heading, description: nil, id: nil, testid: nil, expanded: nil, button_options: {},
      css_class: nil)
      @heading = heading
      @description = description
      @id = id
      @testid = testid
      @expanded = expanded
      @button_options = button_options
      @css_class = css_class
    end

    renders_one :heading
    renders_one :description
    renders_one :callout
    renders_one :body

    private

    def section_classes
      classes = %w[settings no-animate]
      classes.push('expanded') if @expanded
      classes.push(@css_class) if @css_class
      classes.join(' ')
    end

    def title_classes
      %w[gl-heading-2 gl-cursor-pointer !gl-mb-2 js-settings-toggle js-settings-toggle-trigger-only]
    end

    def button_text
      @expanded ? _('Collapse') : _('Expand')
    end

    def aria_label
      @expanded ? "#{_('Collapse')} #{@heading}" : "#{_('Expand')} #{@heading}"
    end
  end
end
