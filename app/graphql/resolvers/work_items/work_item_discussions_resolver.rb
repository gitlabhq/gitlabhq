# frozen_string_literal: true

module Resolvers
  module WorkItems
    class WorkItemDiscussionsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorize :read_work_item
      authorizes_object!

      # this resolver may be calling gitaly as part of parsing notes that contain commit references
      calls_gitaly!

      alias_method :notes_widget, :object

      argument :filter, ::Types::WorkItems::NotesFilterTypeEnum,
        required: false,
        default_value: ::Types::WorkItems::NotesFilterTypeEnum.default_value,
        description: 'Type of notes collection: ALL_NOTES, ONLY_COMMENTS, ONLY_ACTIVITY.'

      type ::Types::Notes::DiscussionType.connection_type, null: true

      def resolve(**args)
        finder = Issuable::DiscussionsListService.new(current_user, work_item, params(args))

        Gitlab::Graphql::ExternallyPaginatedArray.new(
          finder.paginator.cursor_for_previous_page,
          finder.paginator.cursor_for_next_page,
          *finder.execute
        )
      end

      def self.calculate_ext_conn_complexity
        true
      end

      def self.complexity_multiplier(args)
        0.05
      end

      private

      def work_item
        notes_widget.work_item
      end
      strong_memoize_attr :work_item

      def params(args)
        {
          notes_filter: args[:filter],
          cursor: args[:after],
          per_page: self.class.nodes_limit(args, @field, context: context)
        }
      end

      def self.nodes_limit(args, field, **kwargs)
        page_size = field&.max_page_size || kwargs[:context]&.schema&.default_max_page_size
        [args[:first], page_size].compact.min
      end
    end
  end
end
