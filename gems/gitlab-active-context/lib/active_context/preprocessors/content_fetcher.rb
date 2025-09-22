# frozen_string_literal: true

module ActiveContext
  module Preprocessors
    module ContentFetcher
      extend ActiveSupport::Concern

      ContentNotFoundError = Class.new(StandardError)

      class_methods do
        def fetch_content(refs:, query:, collection:, content_field: 'content')
          matches = ::ActiveContext.adapter.client.search(
            user: nil,
            collection: collection,
            query: query
          )

          content_by_id = matches.each_with_object({}) do |match, hash|
            hash[match['id']] = match[content_field]
          end

          with_per_ref_handling(refs, retry_error_types: [], skip_error_types: [ContentNotFoundError]) do |ref|
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
