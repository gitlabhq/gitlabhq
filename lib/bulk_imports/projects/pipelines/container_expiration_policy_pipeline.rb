# frozen_string_literal: true

module BulkImports
  module Projects
    module Pipelines
      class ContainerExpirationPolicyPipeline
        include NdjsonPipeline

        relation_name 'container_expiration_policy'

        extractor ::BulkImports::Common::Extractors::NdjsonExtractor, relation: relation
      end
    end
  end
end
