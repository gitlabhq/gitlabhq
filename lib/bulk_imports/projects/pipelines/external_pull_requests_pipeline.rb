# frozen_string_literal: true

module BulkImports
  module Projects
    module Pipelines
      class ExternalPullRequestsPipeline
        include NdjsonPipeline

        relation_name 'external_pull_requests'

        extractor ::BulkImports::Common::Extractors::NdjsonExtractor, relation: relation
      end
    end
  end
end
