# frozen_string_literal: true

module Gitlab
  module Ci
    module Variables
      class Builder
        include ::Gitlab::Utils::StrongMemoize

        def initialize(pipeline)
          @pipeline = pipeline
        end

        def scoped_variables(job, environment:, dependencies:)
          Gitlab::Ci::Variables::Collection.new.tap do |variables|
            variables.concat(predefined_variables(job)) if pipeline.predefined_vars_in_builder_enabled?
          end
        end

        private

        attr_reader :pipeline

        def predefined_variables(job)
          Gitlab::Ci::Variables::Collection.new.tap do |variables|
            variables.append(key: 'CI_JOB_NAME', value: job.name)
            variables.append(key: 'CI_JOB_STAGE', value: job.stage)
            variables.append(key: 'CI_JOB_MANUAL', value: 'true') if job.action?
            variables.append(key: 'CI_PIPELINE_TRIGGERED', value: 'true') if job.trigger_request

            variables.append(key: 'CI_NODE_INDEX', value: job.options[:instance].to_s) if job.options&.include?(:instance)
            variables.append(key: 'CI_NODE_TOTAL', value: ci_node_total_value(job).to_s)

            # legacy variables
            variables.append(key: 'CI_BUILD_NAME', value: job.name)
            variables.append(key: 'CI_BUILD_STAGE', value: job.stage)
            variables.append(key: 'CI_BUILD_TRIGGERED', value: 'true') if job.trigger_request
            variables.append(key: 'CI_BUILD_MANUAL', value: 'true') if job.action?
          end
        end

        def ci_node_total_value(job)
          parallel = job.options&.dig(:parallel)
          parallel = parallel.dig(:total) if parallel.is_a?(Hash)
          parallel || 1
        end
      end
    end
  end
end
