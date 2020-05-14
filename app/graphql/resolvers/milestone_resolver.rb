# frozen_string_literal: true

module Resolvers
  class MilestoneResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource
    include TimeFrameArguments

    argument :state, Types::MilestoneStateEnum,
              required: false,
              description: 'Filter milestones by state'

    argument :include_descendants, GraphQL::BOOLEAN_TYPE,
              required: false,
              description: 'Return also milestones in all subgroups and subprojects'

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
      }.merge(parent_id_parameter(args))
    end

    def parent
      @parent ||= object.respond_to?(:sync) ? object.sync : object
    end

    def parent_id_parameter(args)
      if parent.is_a?(Group)
        group_parameters(args)
      elsif parent.is_a?(Project)
        { project_ids: parent.id }
      end
    end

    # MilestonesFinder does not check for current_user permissions,
    # so for now we need to keep it here.
    def authorize!
      Ability.allowed?(context[:current_user], :read_milestone, parent) || raise_resource_not_available_error!
    end

    def group_parameters(args)
      return { group_ids: parent.id } unless include_descendants?(args)

      {
        group_ids: parent.self_and_descendants.public_or_visible_to_user(current_user).select(:id),
        project_ids: group_projects.with_issues_or_mrs_available_for_user(current_user)
      }
    end

    def include_descendants?(args)
      args[:include_descendants].present? && Feature.enabled?(:group_milestone_descendants, parent)
    end

    def group_projects
      GroupProjectsFinder.new(
        group: parent,
        current_user: current_user,
        options: { include_subgroups: true }
      ).execute
    end
  end
end
