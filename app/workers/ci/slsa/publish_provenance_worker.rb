# frozen_string_literal: true

module Ci
  module Slsa
    class PublishProvenanceWorker
      include ApplicationWorker

      data_consistency :sticky

      idempotent!

      feature_category :artifact_security

      def perform(build_id)
        build = Ci::Build.find_by_id(build_id)

        PublishProvenanceService.new(build).execute
      end
    end
  end
end
