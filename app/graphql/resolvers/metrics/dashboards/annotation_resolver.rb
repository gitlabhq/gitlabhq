# frozen_string_literal: true

module Resolvers
  module Metrics
    module Dashboards
      class AnnotationResolver < Resolvers::BaseResolver
        argument :from, Types::TimeType,
                 required: true,
                 description: "Timestamp marking date and time from which annotations need to be fetched"

        argument :to, Types::TimeType,
                 required: false,
                 description: "Timestamp marking date and time to which annotations need to be fetched"

        type Types::Metrics::Dashboards::AnnotationType, null: true

        alias_method :dashboard, :object

        def resolve(**args)
          return [] unless dashboard
          return [] unless Feature.enabled?(:metrics_dashboard_annotations, dashboard.environment&.project)

          ::Metrics::Dashboards::AnnotationsFinder.new(dashboard: dashboard, params: args).execute
        end
      end
    end
  end
end
