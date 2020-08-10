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

    type Types::MilestoneType, null: true

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
        start_date: args[:start_date],
        end_date: args[:end_date]
      }.merge(parent_id_parameters(args))
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
