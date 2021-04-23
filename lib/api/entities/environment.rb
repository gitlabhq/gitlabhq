# frozen_string_literal: true

module API
  module Entities
    class Environment < Entities::EnvironmentBasic
      expose :project, using: Entities::BasicProjectDetails
      expose :last_deployment, using: Entities::Deployment, if: { last_deployment: true }
      expose :state
      expose :enable_advanced_logs_querying, if: ->(_, _) { can_read_pod_logs? }

      private

      alias_method :environment, :object

      def enable_advanced_logs_querying
        environment.elastic_stack_available?
      end

      def can_read_pod_logs?
        current_user&.can?(:read_pod_logs, environment.project)
      end

      def current_user
        options[:current_user]
      end
    end
  end
end
