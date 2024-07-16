# frozen_string_literal: true

module Layouts
  class CrudComponent < ViewComponent::Base
    # @param [String] title
    # @param [String] description
    # @param [Number] count
    # @param [String] icon
    # @param [String] toggle_text
    # @param [Hash] options
    def initialize(title, description: nil, count: nil, count_class: nil, icon: nil, toggle_text: nil, options: {})
      @title = title
      @description = description
      @count = count
      @count_class = count_class
      @icon = icon
      @toggle_text = toggle_text
      @options = options
    end

    renders_one :description
    renders_one :actions
    renders_one :body
    renders_one :form
    renders_one :footer
    renders_one :pagination

    delegate :sprite_icon, to: :helpers
  end
end
