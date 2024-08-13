# frozen_string_literal: true

module Layouts
  class SettingsSectionComponent < ViewComponent::Base
    # @param [String] heading
    # @param [String] description
    # @param [String] id
    # @param [String] testid
    # @param [Hash] options
    def initialize(heading, description: nil, id: nil, testid: nil, options: {})
      @heading = heading
      @description = description
      @id = id
      @testid = testid
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
