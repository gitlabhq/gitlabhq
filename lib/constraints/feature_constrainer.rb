# frozen_string_literal: true

module Constraints
  class FeatureConstrainer
    attr_reader :args

    def initialize(*args)
      @args = args
    end

    def matches?(_request)
      Feature.enabled?(*args)
    end
  end
end
