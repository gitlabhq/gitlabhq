# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Quota
        class Deployments < ::Gitlab::Ci::Limit
          include ::Gitlab::Utils::StrongMemoize
          include ActionView::Helpers::TextHelper

          def initialize(namespace, pipeline, command)
            @namespace = namespace
            @pipeline = pipeline
            @command = command
          end

          def enabled?
            limit > 0
          end

          def exceeded?
            return false unless enabled?

            pipeline_deployment_count > limit
          end

          def message
            return unless exceeded?

            "Pipeline has too many deployments! Requested #{pipeline_deployment_count}, but the limit is #{limit}."
          end

          private

          def pipeline_deployment_count
            strong_memoize(:pipeline_deployment_count) do
              @command.pipeline_seed.deployments_count
            end
          end

          def limit
            strong_memoize(:limit) do
              @namespace.actual_limits.ci_pipeline_deployments
            end
          end
        end
      end
    end
  end
end
