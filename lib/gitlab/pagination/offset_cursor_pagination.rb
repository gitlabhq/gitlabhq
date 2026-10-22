# frozen_string_literal: true

module Gitlab
  module Pagination
    # Pages a relation or array by offset while exposing the same cursor interface as
    # Gitlab::Pagination::Keyset::Paginator, so endpoints that cannot do keyset pagination
    # still return `X-Next-Cursor` / `X-Prev-Cursor` instead of page numbers.
    #
    # The cursor encodes the row offset, not a page number, so changing `per_page` between
    # requests keeps pages contiguous. Next-page detection fetches `per_page + 1` rows; no COUNT.
    class OffsetCursorPagination
      include Gitlab::Utils::StrongMemoize

      InvalidCursorError = Class.new(StandardError)

      Converter = Keyset::Paginator::Base64CursorConverter

      OFFSET_KEY = 'offset'
      # OFFSET n reads and discards n rows, so a forged cursor could walk the whole relation.
      # Matches Kaminari::ActiveRecordRelationMethods::MAX_COUNT_LIMIT, where X-Total already stops.
      MAX_OFFSET = 10_000
      private_constant :OFFSET_KEY, :MAX_OFFSET

      def initialize(scope:, cursor: nil, per_page: 20)
        unless per_page.is_a?(Integer) && per_page.between?(1, Kaminari.config.max_per_page)
          raise ArgumentError, "per_page must be an integer between 1 and #{Kaminari.config.max_per_page}"
        end

        @scope = scope
        @per_page = per_page
        @offset = decode_offset(cursor)

        validate_order!
      end

      def records
        page_with_lookahead.first(per_page)
      end

      # A next cursor beyond MAX_OFFSET would be rejected by decode_offset, so stop paging there.
      def has_next_page?
        page_with_lookahead.size > per_page && offset + per_page <= MAX_OFFSET
      end

      def has_previous_page?
        offset > 0
      end

      def cursor_for_next_page
        Converter.dump(OFFSET_KEY => offset + per_page) if has_next_page?
      end

      def cursor_for_previous_page
        Converter.dump(OFFSET_KEY => [offset - per_page, 0].max) if has_previous_page?
      end

      private

      attr_reader :scope, :offset, :per_page

      # One row beyond the page tells us whether a next page exists, without a COUNT.
      def page_with_lookahead
        if scope.is_a?(ActiveRecord::Relation)
          scope.offset(offset).limit(per_page + 1).to_a # rubocop:disable CodeReuse/ActiveRecord -- generic pager
        else
          scope.to_a.slice(offset, per_page + 1) || []
        end
      end
      strong_memoize_attr :page_with_lookahead

      # Postgres gives no stable row order for OFFSET without ORDER BY, so pages would repeat or skip rows.
      def validate_order!
        return unless scope.is_a?(ActiveRecord::Relation) && scope.order_values.empty?

        raise ArgumentError, 'relation must be ordered for offset pagination'
      end

      def decode_offset(cursor)
        return 0 if cursor.blank?
        raise InvalidCursorError, 'cursor must be a string' unless cursor.is_a?(String)

        attributes = Gitlab::Json.safe_parse(Base64.urlsafe_decode64(cursor))
        raise InvalidCursorError, 'cursor must encode an object' unless attributes.is_a?(Hash)

        value = attributes[OFFSET_KEY]
        return value if value.is_a?(Integer) && value.between?(0, MAX_OFFSET)

        raise InvalidCursorError, 'cursor offset is out of range'
      rescue ArgumentError, JSON::ParserError
        raise InvalidCursorError, 'cursor cannot be decoded'
      end
    end
  end
end
