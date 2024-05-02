# frozen_string_literal: true

module Resolvers
  module Snippets
    class BlobsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::Snippets::BlobType.connection_type, null: true
      authorize :read_snippet
      calls_gitaly!
      authorizes_object!

      alias_method :snippet, :object

      argument :paths, [GraphQL::Types::String],
        required: false,
        description: 'Paths of the blobs.'

      def resolve(paths: [])
        return [snippet.blob] if snippet.empty_repo?

        paths = snippet.all_files if paths.empty?
        blobs = snippet.blobs(paths)

        # TODO: Some blobs, e.g. those with non-utf8 filenames, are returned as nil from the
        # repository. We need to provide a flag to notify the user of this until we come up with a
        # way to retrieve and display these blobs. We will be exploring a more holistic solution for
        # this general problem of making all blobs retrievable as part
        # of https://gitlab.com/gitlab-org/gitlab/-/issues/323082, at which point this attribute may
        # be removed.
        context[:unretrievable_blobs?] = blobs.size < paths.size

        blobs
      end
    end
  end
end

Resolvers::Snippets::BlobsResolver.prepend_mod
