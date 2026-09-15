# frozen_string_literal: true

module Types
  module MergeRequests
    # rubocop: disable Graphql/AuthorizeTypes -- reached only through MergeRequestType.diffs, which authorizes read_merge_request
    class DiffConnectionType < GraphQL::Types::Relay::BaseConnection
      graphql_name 'DiffConnection'

      edge_type ::Types::DiffType.edge_type

      field :overflow, GraphQL::Types::Boolean, null: false,
        description: 'Whether files were omitted from the page because it exceeded the diff size limits. ' \
          'Omitted files are absent from `nodes` and are not flagged with `collapsed` or `too_large`.'

      def overflow
        !!object.items.overflow
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
