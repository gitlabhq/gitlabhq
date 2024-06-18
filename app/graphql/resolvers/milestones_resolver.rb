# frozen_string_literal: true

module Resolvers
  class MilestonesResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource
    include TimeFrameArguments
    include LooksAhead

    # authorize before resolution
    authorize :read_milestone
    authorizes_object!

    argument :ids, [GraphQL::Types::ID],
      required: false,
      description: 'Array of global milestone IDs, e.g., `"gid://gitlab/Milestone/1"`.'

    argument :state, Types::MilestoneStateEnum,
      required: false,
      description: 'Filter milestones by state.'

    argument :title, GraphQL::Types::String,
      required: false,
      description: 'Title of the milestone.'

    argument :search_title, GraphQL::Types::String,
      required: false,
      description: 'Search string for the title.'

    argument :containing_date, Types::TimeType,
      required: false,
      description: 'Date the milestone contains.'

    argument :sort, Types::MilestoneSortEnum,
      description: 'Sort milestones by the criteria.',
      required: false,
      default_value: :due_date_asc

    type Types::MilestoneType.connection_type, null: true

    NON_STABLE_CURSOR_SORTS = %i[expired_last_due_date_asc expired_last_due_date_desc].freeze

    def resolve_with_lookahead(**args)
      milestones = apply_lookahead(MilestonesFinder.new(milestones_finder_params(args)).execute)

      if non_stable_cursor_sort?(args[:sort])
        offset_pagination(milestones)
      else
        milestones
      end
    end

    private

    def preloads
      {
        releases: :releases
      }
    end

    def milestones_finder_params(args)
      {
        ids: parse_gids(args[:ids]),
        state: args[:state] || 'all',
        title: args[:title],
        search_title: args[:search_title],
        sort: args[:sort],
        containing_date: args[:containing_date]
      }.merge!(transform_timeframe_parameters(args)).merge!(parent_id_parameters(args))
    end

    def parent
      object
    end

    def parent_id_parameters(args)
      raise NotImplementedError
    end

    def parse_gids(gids)
      gids&.map { |gid| GitlabSchema.parse_gid(gid, expected_type: Milestone).model_id }
    end

    def non_stable_cursor_sort?(sort)
      NON_STABLE_CURSOR_SORTS.include?(sort)
    end
  end
end
