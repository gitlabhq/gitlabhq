module Constraints
  class FeatureConstrainer
    attr_reader :feature

    def initialize(feature)
      @feature = feature
    end

    def matches?(_request)
      Feature.enabled?(feature)
    end
  end
end
