# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Metrics < Chain::Base
          def perform!
            ::Ci::PipelineCreationMetricsWorker.perform_async(
              @pipeline.id,
              inputs_count,
              collect_template_names,
              collect_keyword_usage
            )
          end

          def break?
            false
          end

          private

          def inputs_count
            return unless command.inputs.present?

            command.inputs.size
          end

          def collect_template_names
            command.yaml_processor_result&.included_templates
          end

          def collect_keyword_usage
            yaml_result = command.yaml_processor_result
            return unless yaml_result

            {
              run: yaml_result.uses_keyword?(:run),
              only: yaml_result.uses_keyword?(:only),
              except: yaml_result.uses_keyword?(:except),
              artifacts_reports_junit: yaml_result.uses_nested_keyword?(%i[artifacts reports junit]),
              job_inputs: yaml_result.uses_keyword?(:inputs),
              inputs: yaml_result.uses_inputs?,
              input_rules: yaml_result.uses_input_rules?
            }
          end
        end
      end
    end
  end
end
