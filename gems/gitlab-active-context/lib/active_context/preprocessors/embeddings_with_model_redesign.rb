# frozen_string_literal: true

module ActiveContext
  module Preprocessors
    module EmbeddingsWithModelRedesign
      extend ActiveSupport::Concern

      IndexingError = Class.new(StandardError)

      class_methods do
        def apply_embeddings_with_model_redesign(
          refs:,
          unit_primitive:,
          content_field: :content,
          content_method: nil,
          remove_content: false
        )
          with_batch_handling(refs) do
            docs_to_process = refs.flat_map do |ref|
              next [] unless ref.indexing_embedding_models.any?

              initialize_documents!(ref, content_method, content_field)

              # Create a mapping of reference, document, and embedding models for processing
              ref.documents.map do |doc|
                {
                  ref: ref,
                  doc: doc,
                  models: ref.indexing_embedding_models
                }
              end
            end

            # Group documents by their embedding model configuration
            # This allows processing similar documents together with the same embedding model
            model_groups = docs_to_process.group_by { |item| item[:models].map { |m| [m.field, m.model_name] }.sort }

            model_groups.each_value do |items|
              models = items.first[:models]
              contents = items.map { |item| item[:doc][content_field] }

              embeddings_by_model = generate_embeddings_for_each_model(models: models, contents: contents,
                unit_primitive: unit_primitive)

              # Apply the generated embeddings back to each document
              items.each.with_index do |item, index|
                models.each do |model|
                  item[:doc][model.field] = embeddings_by_model[model.field][index]
                end

                item[:doc].delete(content_field) if remove_content
              end
            end

            refs
          end
        end

        private

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

        def generate_embeddings_for_each_model(models:, contents:, unit_primitive:)
          models.each_with_object({}) do |model, embeddings_by_model|
            embedding = model.generate_embeddings(
              contents,
              unit_primitive: unit_primitive
            )
            embeddings_by_model[model.field] = embedding
          end
        end
      end
    end
  end
end
