# frozen_string_literal: true

module Resolvers
  module MergeRequests
    class DiffsResolver < BaseResolver
      include ::Gitlab::Graphql::Authorize::AuthorizeResource

      DEFAULT_PER_PAGE = 20
      MAX_PER_PAGE = 100
      FIRST_PAGE = 1

      authorize :read_merge_request
      authorizes_object!

      calls_gitaly!

      type ::Types::MergeRequests::DiffConnectionType, null: true

      argument :expanded, GraphQL::Types::Boolean,
        required: false,
        default_value: false,
        description: 'Return full patch text even for files that would otherwise be collapsed for size.'

      def self.calculate_ext_conn_complexity
        true
      end

      def self.complexity_multiplier(_args)
        0.05
      end

      def resolve(**args)
        page = page_from_cursor(args[:after])
        per_page = per_page_from(args[:first])

        collection = object.merge_request_diff.paginated_diffs(page, per_page, { expanded: args[:expanded] })
        git_diffs = collection.diffs
        diffs = git_diffs.to_a

        ::Gitlab::Graphql::MergeRequests::DiffsArray.new(
          previous_cursor(page),
          next_cursor(collection),
          *diffs,
          overflow: git_diffs.overflow?
        )
      end

      private

      def per_page_from(first)
        [first || DEFAULT_PER_PAGE, MAX_PER_PAGE].min
      end

      def page_from_cursor(cursor)
        return FIRST_PAGE if cursor.blank?

        page = Integer(context.schema.cursor_encoder.decode(cursor), exception: false)

        raise Gitlab::Graphql::Errors::ArgumentError, 'Please provide a valid cursor' if page.nil? || page < FIRST_PAGE

        page
      end

      def previous_cursor(page)
        context.schema.cursor_encoder.encode((page - 1).to_s) if page > FIRST_PAGE
      end

      def next_cursor(collection)
        next_page = collection.next_page
        context.schema.cursor_encoder.encode(next_page.to_s) if next_page
      end
    end
  end
end
