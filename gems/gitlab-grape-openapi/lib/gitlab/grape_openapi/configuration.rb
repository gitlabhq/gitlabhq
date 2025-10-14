# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    class Configuration
      attr_accessor :api_version

      def initialize
        @api_version = "v4"
      end
    end
  end
end
