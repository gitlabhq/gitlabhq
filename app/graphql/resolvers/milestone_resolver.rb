# frozen_string_literal: true

module Resolvers
  class MilestoneResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource
    include TimeFrameArguments

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
        state: args[:state] || 'all',
        start_date: args[:start_date],
        end_date: args[:end_date]
      }.merge(parent_id_parameter)
    end

    def parent
      @parent ||= object.respond_to?(:sync) ? object.sync : object
    end

    def parent_id_parameter
      if parent.is_a?(Group)
        { group_ids: parent.id }
      elsif parent.is_a?(Project)
        { project_ids: parent.id }
      end
    end

    # MilestonesFinder does not check for current_user permissions,
    # so for now we need to keep it here.
    def authorize!
      Ability.allowed?(context[:current_user], :read_milestone, parent) || raise_resource_not_available_error!
    end
  end
end
