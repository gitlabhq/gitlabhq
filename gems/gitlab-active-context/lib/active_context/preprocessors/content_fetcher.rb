# frozen_string_literal: true

module ActiveContext
  module Preprocessors
    module ContentFetcher
      extend ActiveSupport::Concern

      ContentNotFoundError = Class.new(StandardError)

      class_methods do
        def fetch_content(refs:, query:, collection:, content_field: 'content', skip_missing_content: false)
          matches = ::ActiveContext.adapter.search(
            user: nil,
            collection: collection,
            query: query,
            source_fields: ['id', content_field]
          )

          content_by_id = matches.each_with_object({}) do |match, hash|
            hash[match['id']] = match[content_field]
          end

          error_opts = if skip_missing_content
                         { skip_error_types: [ContentNotFoundError] }
                       else
                         { retry_error_types: [ContentNotFoundError] }
                       end

          with_per_ref_handling(refs, **error_opts) do |ref|
            unless content_by_id.key?(ref.identifier)
              raise ContentNotFoundError, "content not found for chunk with id: #{ref.identifier}"
            end

            ref.documents << { content: content_by_id[ref.identifier] }
            ref
          end
        end
      end
    end
  end
end
