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
          content_field: :content,
          content_method: nil,
          remove_content: true
        )
          refs.each do |ref|
            initialize_documents!(ref, content_method, content_field)
            versions = ref.embedding_versions
            batch_size = (BATCH_SIZE.to_f / versions.count).ceil

            ref.documents.each_slice(batch_size) do |docs_batch|
              contents = docs_batch.pluck(content_field)

              embeddings_by_version = generate_embeddings_for_each_version(versions, contents)

              docs_batch.each_with_index do |doc, index|
                ref.embedding_versions.each do |version|
                  doc[version[:field]] = embeddings_by_version[version[:field]][index]
                end
                doc.delete(content_field) if remove_content
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

        def generate_embeddings_for_each_version(versions, contents)
          versions.each_with_object({}) do |version, embeddings_by_version|
            embedding = ActiveContext::Embeddings.generate_embeddings(contents, model: version[:model])
            embeddings_by_version[version[:field]] = embedding
          end
        end
      end
    end
  end
end
