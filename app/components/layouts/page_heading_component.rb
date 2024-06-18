# frozen_string_literal: true

module Layouts
  class PageHeadingComponent < ViewComponent::Base
    # @param [String] heading
    def initialize(heading)
      @heading = heading
    end

    renders_one :heading
    renders_one :actions
    renders_one :description
  end
end
