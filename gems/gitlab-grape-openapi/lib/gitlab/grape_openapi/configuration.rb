# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    class Configuration
      attr_accessor :api_version, :servers, :security_schemes, :info

      def initialize
        @api_version = "v4"
        @info = nil
        @servers = []
        @security_schemes = []
      end
    end
  end
end
