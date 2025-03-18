# frozen_string_literal: true

module ActiveContext
  module Preprocessors
    module Embeddings
      extend ActiveSupport::Concern

      IndexingError = Class.new(StandardError)

      # Vertex bulk limit is 250 so we choose a lower batch size
      # Gitlab::Llm::VertexAi::Embeddings::Text::BULK_LIMIT
      BATCH_SIZE = 100

      class_methods do
        def bulk_embeddings(refs)
          unless respond_to?(:embedding_content)
            raise IndexingError, "#{self} should implement :embedding_content method"
          end

          refs.each_slice(BATCH_SIZE) do |batch|
            contents = batch.map { |ref| embedding_content(ref) }
            embeddings = ActiveContext::Embeddings.generate_embeddings(contents)

            batch.each_with_index do |ref, index|
              ref.embedding = embeddings[index]
            end
          end

          refs
        rescue StandardError => e
          ::ActiveContext::Logger.exception(e)
          refs # we will generate each embedding on the fly if bulk fails
        end
      end
    end
  end
end
