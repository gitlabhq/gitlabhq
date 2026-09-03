# frozen_string_literal: true

module Resolvers
  module Projects
    class UnprotectedBranchesResolver < BaseResolver
      type GraphQL::Types::String.connection_type, null: true

      calls_gitaly!

      alias_method :project, :object

      argument :search, GraphQL::Types::String,
        required: false,
        description: 'Search query to filter branch names (case-insensitive).'

      def resolve(search: nil, first: nil, after: nil)
        limit = compute_limit(first)

        return empty_result if limit <= 0

        dropdown = ProtectableDropdown.new(project, :branches)
        result = dropdown.paginated_protectable_ref_names(
          limit: limit,
          page_token: after,
          search: search
        )

        next_cursor = result[:next_cursor]

        Gitlab::Graphql::ExternallyPaginatedArray.new(
          nil, next_cursor, *result[:names], has_next_page: next_cursor.present?
        )
      rescue Gitlab::Git::InvalidPageToken
        raise Gitlab::Graphql::Errors::ArgumentError, 'Invalid pagination cursor'
      end

      private

      def compute_limit(first)
        [first, field.max_page_size || context.schema.default_max_page_size].compact.min # rubocop:disable Graphql/Descriptions -- false positive on `field`
      end

      def empty_result
        Gitlab::Graphql::ExternallyPaginatedArray.new(nil, nil, has_next_page: false)
      end
    end
  end
end
