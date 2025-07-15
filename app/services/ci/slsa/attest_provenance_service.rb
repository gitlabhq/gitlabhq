# frozen_string_literal: true

require 'digest'

module Ci
  module Slsa
    class AttestProvenanceService < ::BaseService
      def initialize(build)
        @build = build
      end

      def execute
        return ServiceResponse.error(message: "Unable to find build") unless @build

        Ci::Slsa::ProvenanceStatement.from_build(@build).to_json

        # TODO: upload statement to glgo.
      end
    end
  end
end

Ci::Slsa::AttestProvenanceService.prepend_mod
