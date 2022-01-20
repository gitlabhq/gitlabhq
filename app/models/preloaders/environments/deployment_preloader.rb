# frozen_string_literal: true

module Preloaders
  module Environments
    # This class is to batch-load deployments of multiple environments.
    # The deployments to batch-load are fetched using UNION of N selects in a single query instead of default scoping with `IN (environment_id1, environment_id2 ...)`.
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/345672#note_761852224 for more details.
    class DeploymentPreloader
      attr_reader :environments

      def initialize(environments)
        @environments = environments
      end

      def execute_with_union(association_name, association_attributes)
        load_deployment_association(association_name, association_attributes)
      end

      private

      def load_deployment_association(association_name, association_attributes)
        return unless environments.present?

        union_arg = environments.inject([]) do |result, environment|
          result << environment.association(association_name).scope
        end

        union_sql = Deployment.from_union(union_arg).to_sql

        deployments = Deployment
                        .from("(#{union_sql}) #{::Deployment.table_name}")
                        .preload(association_attributes)

        deployments_by_environment_id = deployments.index_by(&:environment_id)

        environments.each do |environment|
          environment.association(association_name).target = deployments_by_environment_id[environment.id]
          environment.association(association_name).loaded!
        end
      end
    end
  end
end
