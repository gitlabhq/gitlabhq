# frozen_string_literal: true

module Gitlab
  module Graphql
    StandardGraphqlError = Class.new(StandardError)

    def self.enabled?
      Feature.enabled?(:graphql, default_enabled: true)
    end
  end
end
