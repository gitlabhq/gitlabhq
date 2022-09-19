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

        # Not using Gitlab::SQL::Union as `order_by` in the SQL constructed is ignored.
        # See:
        #   1) https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/sql/union.rb#L7
        #   2) https://gitlab.com/gitlab-org/gitlab/-/issues/353966#note_860928647
        union_sql = environments.map do |environment|
          "(#{environment.association(association_name).scope.to_sql})"
        end.join(' UNION ')

        deployments = Deployment
                        .from("(#{union_sql}) #{::Deployment.table_name}")
                        .preload(association_attributes)

        deployments_by_environment_id = deployments.index_by(&:environment_id)

        environments.each do |environment|
          associated_deployment = deployments_by_environment_id[environment.id]

          environment.association(association_name).target = associated_deployment
          environment.association(association_name).loaded!

          next unless associated_deployment

          # `last?` in DeploymentEntity requires this environment to be loaded
          associated_deployment.association(:environment).target = environment
          associated_deployment.association(:environment).loaded!
        end
      end
    end
  end
end
