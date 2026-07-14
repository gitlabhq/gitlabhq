# frozen_string_literal: true

module Resolvers
  module Notes
    # Unlike the inherited NoteableInterface#discussions (persisted notes only),
    # this delegates to Issuable::DiscussionsListService so resource events
    # (label, milestone, and state changes) are folded in as synthetic system notes.
    class DiscussionsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorize :read_note
      authorizes_object!

      # this resolver may be calling gitaly as part of parsing notes that contain commit references
      calls_gitaly!

      argument :filter, ::Types::WorkItems::NotesFilterTypeEnum,
        required: false,
        default_value: ::Types::WorkItems::NotesFilterTypeEnum.default_value,
        description: 'Type of notes collection: ALL_NOTES, ONLY_COMMENTS, ONLY_ACTIVITY.'

      argument :sort, ::Types::WorkItems::DiscussionsSortEnum,
        required: false,
        default_value: ::Types::WorkItems::DiscussionsSortEnum.default_value,
        description: 'Sort order for the discussions.'

      type ::Types::Notes::DiscussionType.connection_type, null: true

      def self.calculate_ext_conn_complexity
        true
      end

      def self.complexity_multiplier(_args)
        0.05
      end

      def self.nodes_limit(args, field, **kwargs)
        page_size = field&.max_page_size || kwargs[:context]&.schema&.default_max_page_size
        [args[:first], page_size].compact.min
      end

      def resolve(**args)
        finder = Issuable::DiscussionsListService.new(current_user, object, params(args))

        # precompute noteable_url once so that it is reused for all notes
        context.scoped_set!(:noteable_url, ::Gitlab::UrlBuilder.build(object))

        Gitlab::Graphql::ExternallyPaginatedArray.new(
          finder.paginator.cursor_for_previous_page,
          finder.paginator.cursor_for_next_page,
          *finder.execute
        )
      end

      private

      def params(args)
        {
          notes_filter: args[:filter],
          sort: args[:sort],
          cursor: args[:after],
          per_page: self.class.nodes_limit(args, @field, context: context)
        }
      end
    end
  end
end
