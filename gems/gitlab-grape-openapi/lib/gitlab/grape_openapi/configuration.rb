# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    class Configuration
      attr_accessor :api_version, :api_prefix, :servers, :security_schemes, :info

      def initialize
        @api_prefix = "api"
        @api_version = "v1"
        @info = nil

        @servers = []
        @security_schemes = []
      end
    end
  end
end
