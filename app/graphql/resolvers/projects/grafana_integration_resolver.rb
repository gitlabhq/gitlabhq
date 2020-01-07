# frozen_string_literal: true

module Resolvers
  module Projects
    class GrafanaIntegrationResolver < BaseResolver
      type Types::GrafanaIntegrationType, null: true

      alias_method :project, :object

      def resolve(**args)
        return unless project.is_a? Project

        project.grafana_integration
      end
    end
  end
end
