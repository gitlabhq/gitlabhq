# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    class Generator
      def initialize(api_classes, options = {})
        @api_classes = api_classes
        @options = options
      end

      def generate
        # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/572530
        '{}'
      end
    end
  end
end
