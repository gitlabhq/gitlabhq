# frozen_string_literal: true

module Layouts
  class SettingsSectionComponent < ViewComponent::Base
    # @param [String] heading
    # @param [String] description
    # @param [String] id
    # @param [String] testid
    def initialize(heading, description: nil, id: nil, testid: nil)
      @heading = heading
      @description = description
      @id = id
      @testid = testid
    end

    renders_one :heading
    renders_one :description
    renders_one :body
  end
end
