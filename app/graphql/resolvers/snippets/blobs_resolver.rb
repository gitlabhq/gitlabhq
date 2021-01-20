# frozen_string_literal: true

module Resolvers
  module Snippets
    class BlobsResolver < BaseResolver
      prepend ManualAuthorization
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::Snippets::BlobType.connection_type, null: true
      authorize :read_snippet

      alias_method :snippet, :object

      argument :paths, [GraphQL::STRING_TYPE],
               required: false,
               description: 'Paths of the blobs.'

      def resolve(**args)
        authorize!(snippet)

        return [snippet.blob] if snippet.empty_repo?

        paths = Array(args.fetch(:paths, []))

        if paths.empty?
          snippet.blobs
        else
          snippet.repository.blobs_at(transformed_blob_paths(paths))
        end
      end

      private

      def transformed_blob_paths(paths)
        ref = snippet.default_branch
        paths.map { |path| [ref, path] }
      end
    end
  end
end
