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
          unit_primitive:,
          content_field: :content,
          content_method: nil,
          remove_content: true
        )
          with_batch_handling(refs) do
            docs_to_process = refs.flat_map do |ref|
              next [] unless ref.embedding_versions.any?

              initialize_documents!(ref, content_method, content_field)

              # Create a mapping of reference, document, and embedding versions for processing
              ref.documents.map do |doc|
                {
                  ref: ref,
                  doc: doc,
                  versions: ref.embedding_versions
                }
              end
            end

            # Process documents in batches to avoid rate limits
            docs_to_process.each_slice(BATCH_SIZE) do |batch|
              # Group documents by their embedding version configuration
              # This allows processing similar documents together with the same embedding model
              version_groups = batch.group_by { |item| item[:versions].map { |v| [v[:field], v[:model]] }.sort }

              version_groups.each_value do |items|
                versions = items.first[:versions]
                contents = items.map { |item| item[:doc][content_field] }

                embeddings_by_version = generate_embeddings_for_each_version(versions: versions, contents: contents,
                  unit_primitive: unit_primitive)

                # Apply the generated embeddings back to each document
                items.each.with_index do |item, index|
                  versions.each do |version|
                    item[:doc][version[:field]] = embeddings_by_version[version[:field]][index]
                  end

                  item[:doc].delete(content_field) if remove_content
                end
              end
            end

            refs
          end
        end

        # Initializes the documents for a reference if they don't exist
        # and populates the content field if a content_method is provided
        def initialize_documents!(ref, content_method, content_field)
          return unless content_method && ref.respond_to?(content_method)

          ref.documents << {} if ref.documents.empty?

          ref.documents.each do |doc|
            next if doc.key?(content_field)

            doc[content_field] = ref.send(content_method) # rubocop: disable GitlabSecurity/PublicSend -- method is defined elsewhere
          end
        end

        def generate_embeddings_for_each_version(versions:, contents:, unit_primitive:)
          versions.each_with_object({}) do |version, embeddings_by_version|
            embedding = ActiveContext::Embeddings.generate_embeddings(contents, model: version[:model],
              unit_primitive: unit_primitive)
            embeddings_by_version[version[:field]] = embedding
          end
        end
      end
    end
  end
end
