# frozen_string_literal: true

module Constraints
  class FeatureConstrainer
    attr_reader :feature, :thing, :default_enabled

    def initialize(feature, thing, default_enabled)
      @feature, @thing, @default_enabled = feature, thing, default_enabled
    end

    def matches?(_request)
      Feature.enabled?(feature, @thing, default_enabled: true)
    end
  end
end
