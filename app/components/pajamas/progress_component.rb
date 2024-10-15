# frozen_string_literal: true

module Pajamas
  class ProgressComponent < Pajamas::Component
    VARIANT_OPTIONS = [:primary, :success].freeze

    def initialize(value: 0, variant: :primary)
      @value = value
      @variant = filter_attribute(variant, VARIANT_OPTIONS, default: :primary)
    end
  end
end
