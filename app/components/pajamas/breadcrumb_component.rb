# frozen_string_literal: true

module Pajamas
  class BreadcrumbComponent < Pajamas::Component
    def initialize(
      **html_options
    )
      @html_options = html_options
    end

    private

    attr_reader :html_options

    renders_many :items, BreadcrumbItemComponent
  end
end
