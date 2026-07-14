# frozen_string_literal: true

module Resolvers
  module Wikis
    class WikiPagesResolver < BaseResolver
      description 'List wiki pages for a container.'

      authorizes_object!
      authorize :read_wiki

      calls_gitaly!

      type Types::Wikis::WikiPageType.connection_type, null: true

      def resolve(**args)
        wiki = Wiki.for_container(object, current_user)

        limit = page_size(args[:first])
        offset = decode_cursor(args[:after])

        # `list_pages` treats `limit: 0` as unlimited at Gitaly, so bail out instead of
        # re-introducing the full fetch when no positive page size is requested.
        return empty_result if limit <= 0

        # Fetch one extra "probe" row so we can tell a full final page from a full page with
        # more behind it. `size == limit` cannot distinguish them (no backend cursor here),
        # which would emit a phantom cursor and cost the consumer an empty Gitaly round-trip
        # at every exact multiple of `limit`. `list_pages` only trims when its limit is > 0,
        # so `limit + 1` fetches the probe row; `pages.first(limit)` drops it from the result.
        pages = wiki.list_pages(limit: limit + 1, offset: offset)

        has_next_page = pages.size > limit
        end_cursor = encode_cursor(offset + limit) if has_next_page

        metas = pages.first(limit).filter_map(&:find_or_create_meta)

        Gitlab::Graphql::ExternallyPaginatedArray.new(nil, end_cursor, *metas, has_next_page: has_next_page)
      end

      private

      # Most restrictive of the requested page size, the field's max page size and the
      # schema default. Mirrors Resolvers::Repositories::CommitsResolver#compute_limit.
      def page_size(first)
        [first, field.max_page_size || context.schema.default_max_page_size].compact.min # rubocop:disable Graphql/Descriptions -- false positive on `field`
      end

      def encode_cursor(offset)
        Base64.strict_encode64(offset.to_s)
      end

      def decode_cursor(cursor)
        return 0 if cursor.blank?

        # Floor at 0 so a hand-crafted cursor decoding to a negative integer can't flow
        # through to `list_pages(offset:)` and on to Gitaly.
        [Integer(Base64.strict_decode64(cursor), 10), 0].max
      rescue ArgumentError, TypeError
        raise Gitlab::Graphql::Errors::ArgumentError, 'Invalid pagination cursor'
      end

      def empty_result
        Gitlab::Graphql::ExternallyPaginatedArray.new(nil, nil, has_next_page: false)
      end
    end
  end
end
