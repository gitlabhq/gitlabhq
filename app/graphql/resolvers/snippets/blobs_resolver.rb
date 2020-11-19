# frozen_string_literal: true

module Resolvers
  module Snippets
    class BlobsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::Snippets::BlobType.connection_type, null: true

      alias_method :snippet, :object

      argument :paths, [GraphQL::STRING_TYPE],
               required: false,
               description: 'Paths of the blobs'

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

      def authorized_resource?(snippet)
        Ability.allowed?(context[:current_user], :read_snippet, snippet)
      end

      private

      def transformed_blob_paths(paths)
        ref = snippet.default_branch
        paths.map { |path| [ref, path] }
      end
    end
  end
end
