# frozen_string_literal: true

module Gitlab
  module Reflections
    module Relationships
      # Builds a relationship array from relationship extractors
      class Builder
        def initialize(ar_extractor = nil)
          @ar_extractor = ar_extractor || Gitlab::Reflections::Relationships::RelationshipExtractor.new
        end

        def build_relationships
          ar_relationships = @ar_extractor.extract

          # Combine and transform relationships
          Transformers::Pipeline.new(
            Transformers::Deduplicate,
            Transformers::Validate
          ).execute(ar_relationships)
        end
      end
    end
  end
end
