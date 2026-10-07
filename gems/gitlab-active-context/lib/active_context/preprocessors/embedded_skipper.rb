# frozen_string_literal: true

module ActiveContext
  module Preprocessors
    module EmbeddedSkipper
      extend ActiveSupport::Concern

      class_methods do
        def skip_embedded(
          refs:,
          collection:,
          queue_name: nil,
          next_model_only: false,
          current_model_only: false)
          fields = embedding_fields(
            collection: collection, next_model_only: next_model_only, current_model_only: current_model_only
          )
          return { successful: refs, failed: [] } if fields.empty?

          ids = refs.map(&:identifier)
          query = ::ActiveContext::Query.and(
            ::ActiveContext::Query.filter(id: ids),
            *fields.map { |field| ::ActiveContext::Query.exists(field) }
          ).limit(ids.size)

          documents = collection.search(user: nil, query: query, source_fields: ['id'])
          embedded_ids = documents.to_set { |doc| doc['id'] }
          refs_without_embeddings = refs.reject { |ref| embedded_ids.include?(ref.identifier) }

          ::ActiveContext::Logger.info(
            message: 'skip_embedded', class_name: name, queue_name: queue_name,
            refs_count: refs.size, skipped_count: refs.size - refs_without_embeddings.size
          )

          { successful: refs_without_embeddings, failed: [] }
        rescue StandardError => e
          ::ActiveContext::Logger.exception(e, handling: :skipped, class_name: name, queue_name: queue_name,
            preprocessor: 'skip_embedded', refs_count: refs.size)

          { successful: refs, failed: [] }
        end

        private

        def embedding_fields(collection:, next_model_only:, current_model_only:)
          record = collection.collection_record
          current_model = record&.current_indexing_embedding_model
          next_model = record&.next_indexing_embedding_model

          models = if next_model_only
                     [next_model]
                   elsif current_model_only
                     [current_model]
                   else
                     [current_model, next_model]
                   end

          models.compact.map { |model| model[:field].to_s }
        end
      end
    end
  end
end
