# frozen_string_literal: true

module Resolvers
  class MilestonesResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource
    include TimeFrameArguments

    argument :ids, [GraphQL::ID_TYPE],
             required: false,
             description: 'Array of global milestone IDs, e.g., "gid://gitlab/Milestone/1"'

    argument :state, Types::MilestoneStateEnum,
             required: false,
             description: 'Filter milestones by state'

    argument :title, GraphQL::STRING_TYPE,
             required: false,
             description: 'The title of the milestone'

    argument :search_title, GraphQL::STRING_TYPE,
             required: false,
             description: 'A search string for the title'

    argument :containing_date, Types::TimeType,
             required: false,
             description: 'A date that the milestone contains'

    type Types::MilestoneType.connection_type, null: true

    def resolve(**args)
      validate_timeframe_params!(args)

      authorize!

      MilestonesFinder.new(milestones_finder_params(args)).execute
    end

    private

    def milestones_finder_params(args)
      {
        ids: parse_gids(args[:ids]),
        state: args[:state] || 'all',
        title: args[:title],
        search_title: args[:search_title],
        containing_date: args[:containing_date]
      }.merge!(timeframe_parameters(args)).merge!(parent_id_parameters(args))
    end

    def timeframe_parameters(args)
      if args[:timeframe]
        args[:timeframe].transform_keys { |k| :"#{k}_date" }
      else
        args.slice(:start_date, :end_date)
      end
    end

    def parent
      synchronized_object
    end

    def parent_id_parameters(args)
      raise NotImplementedError
    end

    # MilestonesFinder does not check for current_user permissions,
    # so for now we need to keep it here.
    def authorize!
      Ability.allowed?(context[:current_user], :read_milestone, parent) || raise_resource_not_available_error!
    end

    def parse_gids(gids)
      gids&.map { |gid| GitlabSchema.parse_gid(gid, expected_type: Milestone).model_id }
    end
  end
end
