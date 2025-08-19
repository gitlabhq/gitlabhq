# frozen_string_literal: true

require 'digest'

module Ci
  module Slsa
    class PublishProvenanceService < ::BaseService
      def initialize(build)
        @build = build
      end

      def execute
        return ServiceResponse.error(message: "Unable to find build") unless @build

        # TODO: sign statement using `cosign`.
        ServiceResponse.success(message: "OK")
      end
    end
  end
end

Ci::Slsa::PublishProvenanceService.prepend_mod
