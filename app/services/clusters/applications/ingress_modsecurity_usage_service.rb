# frozen_string_literal: true

# rubocop: disable CodeReuse/ActiveRecord
module Clusters
  module Applications
    ##
    # This service measures usage of the Modsecurity Web Application Firewall across the entire
    # instance's deployed environments.
    #
    # The default configuration is`AUTO_DEVOPS_MODSECURITY_SEC_RULE_ENGINE=DetectionOnly` so we
    # measure non-default values via definition of either ci_variables or ci_pipeline_variables.
    # Since both these values are encrypted, we must decrypt and count them in memory.
    #
    # NOTE: this service is an approximation as it does not yet take into account `environment_scope` or `ci_group_variables`.
    ##
    class IngressModsecurityUsageService
      ADO_MODSEC_KEY = "AUTO_DEVOPS_MODSECURITY_SEC_RULE_ENGINE"

      def initialize(blocking_count: 0, disabled_count: 0)
        @blocking_count = blocking_count
        @disabled_count = disabled_count
      end

      def execute
        conditions = -> { merge(::Environment.available).merge(::Deployment.success).where(key: ADO_MODSEC_KEY) }

        ci_pipeline_var_enabled =
          ::Ci::PipelineVariable
            .joins(pipeline: { environments: :last_visible_deployment })
            .merge(conditions)
            .order('deployments.environment_id, deployments.id DESC')

        ci_var_enabled =
          ::Ci::Variable
            .joins(project: { environments: :last_visible_deployment })
            .merge(conditions)
            .merge(
              # Give priority to pipeline variables by excluding from dataset
              ::Ci::Variable.joins(project: :environments).where.not(
                environments: { id: ci_pipeline_var_enabled.select('DISTINCT ON (deployments.environment_id) deployments.environment_id') }
              )
            ).select('DISTINCT ON (deployments.environment_id) ci_variables.*')

        sum_modsec_config_counts(
          ci_pipeline_var_enabled.select('DISTINCT ON (deployments.environment_id) ci_pipeline_variables.*')
        )
        sum_modsec_config_counts(ci_var_enabled)

        {
          ingress_modsecurity_blocking: @blocking_count,
          ingress_modsecurity_disabled: @disabled_count
        }
      end

      private

      # These are encrypted so we must decrypt and count in memory
      def sum_modsec_config_counts(dataset)
        dataset.each do |var|
          case var.value
          when "On" then @blocking_count += 1
          when "Off" then @disabled_count += 1
            # `else` could be default or any unsupported user input
          end
        end
      end
    end
  end
end
