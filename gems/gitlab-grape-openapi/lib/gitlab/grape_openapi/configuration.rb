# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    class Configuration
      attr_accessor :api_version, :api_prefix, :excluded_api_classes, :servers, :security_schemes, :info,
        :tag_overrides

      def initialize
        @api_prefix = "api"
        @api_version = "v1"
        @excluded_api_classes = []
        @info = nil

        @servers = []
        @security_schemes = []

        @tag_overrides = {}
      end
    end
  end
end
