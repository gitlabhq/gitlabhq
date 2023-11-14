# frozen_string_literal: true

module BulkImports
  module Projects
    module Pipelines
      class ReleasesPipeline
        include NdjsonPipeline

        relation_name 'releases'

        extractor ::BulkImports::Common::Extractors::NdjsonExtractor, relation: relation

        def on_finish
          portable.releases.find_each do |release|
            create_release_evidence(release)
          end
        end

        private

        def create_release_evidence(release)
          return if release.historical_release? || release.upcoming_release?

          ::Releases::CreateEvidenceWorker.perform_async(release.id)
        end
      end
    end
  end
end
