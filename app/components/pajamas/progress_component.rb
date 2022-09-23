# frozen_string_literal: true

module Pajamas
  class ProgressComponent < Pajamas::Component
    def initialize(value: 0, variant: :primary)
      @value = value
      @variant = filter_attribute(variant, VARIANT_OPTIONS, default: :primary)
    end

    VARIANT_OPTIONS = [:primary, :success].freeze
  end
end
