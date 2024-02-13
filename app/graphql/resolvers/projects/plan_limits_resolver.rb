# frozen_string_literal: true

module Resolvers
  module Projects
    class PlanLimitsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::ProjectPlanLimitsType, null: false

      authorize :read_project

      def resolve
        authorize!(object)

        schedule_allowed = Ability.allowed?(current_user, :read_ci_pipeline_schedules_plan_limit, object)

        {
          ci_pipeline_schedules: schedule_allowed ? object.actual_limits.ci_pipeline_schedules : nil
        }
      end
    end
  end
end
