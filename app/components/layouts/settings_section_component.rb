# frozen_string_literal: true

module Layouts
  class SettingsSectionComponent < ViewComponent::Base
    DEFAULT_HEADING_CLASSES = 'gl-heading-2'

    # @param [String] heading
    # @param [String] description
    # @param [String] id
    # @param [String] testid
    # @param [String] heading_classes - size utilities for the `h2`, for example `gl-heading-3` when the
    #   section sits below another heading such as a tab
    # @param [Hash] options
    def initialize(
      heading, description: nil, id: nil, testid: nil, heading_classes: DEFAULT_HEADING_CLASSES,
      options: {})
      @heading = heading
      @description = description
      @id = id
      @testid = testid
      @heading_classes = heading_classes
      @options = options
    end

    renders_one :heading
    renders_one :description
    renders_one :body

    def options_attrs
      data = @options[:data] || {}
      data[:testid] ||= @testid

      attrs = {
        class: [@options[:class]].flatten.compact,
        data: data
      }
      attrs[:id] = @id if @id

      @options.merge(attrs)
    end
  end
end
