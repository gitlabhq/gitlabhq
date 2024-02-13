# frozen_string_literal: true

module Pajamas
  class BreadcrumbItemComponent < Pajamas::Component
    def initialize(href:, text:)
      @href = href
      @text = text
    end
  end
end
