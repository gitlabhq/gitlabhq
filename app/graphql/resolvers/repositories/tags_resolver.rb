# frozen_string_literal: true

module Resolvers
  module Repositories
    class TagsResolver < BaseResolver
      type Types::Repositories::TagType.connection_type, null: true

      argument :search, GraphQL::Types::String,
        required: false,
        description: 'Filter tags by name. Supports `^` for prefix, `$` for suffix, and `*` as a wildcard.'

      argument :sort, Types::Repositories::TagSortEnum,
        required: false,
        default_value: 'updated_desc',
        description: 'Sort tags by the criteria. Defaults to `UPDATED_DESC`.'

      calls_gitaly!

      alias_method :repository, :object

      def resolve(**arguments)
        first = arguments.delete(:first)
        after = arguments.delete(:after)
        limit = compute_limit(first)

        return empty_result if limit <= 0

        page_token = decode_cursor(after)
        search = arguments[:search].presence
        sort = arguments[:sort]

        if search
          paginate_in_memory(all_matching_tags(search, sort), page_token, limit)
        else
          paginate_via_gitaly(sort, page_token, limit)
        end
      rescue Gitlab::Git::InvalidPageToken => e
        raise Gitlab::Graphql::Errors::ArgumentError, e.message
      end

      private

      # Gitaly can only paginate the full tag list, so a search filter is
      # applied to the full list and paginated here, the same as the REST API.
      def paginate_via_gitaly(sort, page_token, limit)
        finder = ::TagsFinder.new(repository, sort: sort, page_token: page_token, per_page: limit)
        tags = finder.execute(gitaly_pagination: true).to_a
        # Gitaly does not report whether more tags follow, so a final page that
        # exactly fills the limit still reports hasNextPage and yields an empty
        # last fetch.
        has_next_page = tags.size == limit

        externally_paginated(tags, has_next_page)
      end

      def all_matching_tags(search, sort)
        ::TagsFinder.new(repository, search: search, sort: sort).execute.to_a
      end

      def paginate_in_memory(tags, page_token, limit)
        start = 0

        if page_token
          index = tags.index { |tag| tag.name == page_token }
          raise Gitlab::Graphql::Errors::ArgumentError, "Invalid page token: #{page_token}" unless index

          start = index + 1
        end

        externally_paginated(tags[start, limit].to_a, tags.size > start + limit)
      end

      def externally_paginated(tags, has_next_page)
        end_cursor = encode_cursor(tags.last.name) if has_next_page && tags.any?

        Gitlab::Graphql::ExternallyPaginatedArray.new(nil, end_cursor, *tags, has_next_page: has_next_page)
      end

      def compute_limit(first)
        # rubocop:disable Graphql/Descriptions -- `field` here is the resolver's field, not a field definition
        [first, field.max_page_size || context.schema.default_max_page_size].compact.min
        # rubocop:enable Graphql/Descriptions
      end

      def encode_cursor(tag_name)
        Base64.strict_encode64(tag_name)
      end

      def decode_cursor(cursor)
        return if cursor.blank?

        Base64.strict_decode64(cursor)
      rescue ArgumentError
        raise Gitlab::Graphql::Errors::ArgumentError, "Invalid page token: #{cursor}"
      end

      def empty_result
        Gitlab::Graphql::ExternallyPaginatedArray.new(nil, nil, has_next_page: false)
      end
    end
  end
end
