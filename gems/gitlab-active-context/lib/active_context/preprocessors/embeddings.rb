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
        def apply_embeddings(
          refs:,
          target_field:,
          content_field: :content,
          content_method: nil,
          remove_content_field: true
        )
          refs.each do |ref|
            initialize_documents!(ref, content_method, content_field)

            ref.documents.each_slice(BATCH_SIZE) do |docs_batch|
              contents = docs_batch.pluck(content_field)
              embeddings = ActiveContext::Embeddings.generate_embeddings(contents)

              docs_batch.each_with_index do |doc, index|
                doc[target_field] = embeddings[index]
                doc.delete(content_field) if remove_content_field
              end
            end
          end

          refs
        rescue StandardError => e
          ErrorHandler.log_and_raise_error(e)
        end

        def initialize_documents!(ref, content_method, content_field)
          return unless content_method && ref.respond_to?(content_method)

          ref.documents << {} if ref.documents.empty?

          ref.documents.each do |doc|
            next if doc.key?(content_field)

            doc[content_field] = ref.send(content_method) # rubocop: disable GitlabSecurity/PublicSend -- method is defined elsewhere
          end
        end
      end
    end
  end
end
