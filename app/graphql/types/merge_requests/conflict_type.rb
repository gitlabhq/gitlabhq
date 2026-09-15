# frozen_string_literal: true

module Types
  module MergeRequests
    class ConflictType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- authorized by the parent merge request
      graphql_name 'MergeRequestConflict'
      description 'File with conflicts in a merge request that cannot be merged.'

      authorize_granular_token skip_reason: :parent_authorizes

      field :our_path, GraphQL::Types::String, null: true,
        description: 'Path of the conflicting file on the source branch.'

      field :their_path, GraphQL::Types::String, null: true,
        description: 'Path of the conflicting file on the target branch.'

      field :content, GraphQL::Types::String, null: true,
        description: 'Raw content of the conflicting file, including Git conflict markers. ' \
          'Returns null for files with unsupported encodings (binary, non-UTF-8).'

      def content
        object.content
      rescue Gitlab::Git::Conflict::File::UnsupportedEncoding
        nil
      end
    end
  end
end
