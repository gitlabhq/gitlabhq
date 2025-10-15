# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    class Configuration
      attr_accessor :api_version, :servers, :security_schemes

      def initialize
        @api_version = "v4"
        @servers = []
        @security_schemes = []
      end
    end
  end
end
