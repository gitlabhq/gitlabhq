# frozen_string_literal: true

module Ci
  module Slsa
    class PublishStatementWorker
      include ApplicationWorker

      data_consistency :sticky

      idempotent!

      feature_category :continuous_integration

      def perform(build_id)
        build = Ci::Build.find_by_id(build_id)

        AttestProvenanceService.new(build).execute
      end
    end
  end
end
