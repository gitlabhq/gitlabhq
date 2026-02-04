# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Build
        class PipelineVariablesArtifactBuilder
          include Gitlab::Utils::StrongMemoize

          FILE_TYPE = :pipeline_variables

          def initialize(pipeline, variables_attributes)
            @pipeline = pipeline
            @variables_attributes = variables_attributes
          end

          def run
            return if variables.empty?

            variables.each(&:validate!)

            pipeline.build_pipeline_artifacts_pipeline_variables(
              partition_id: pipeline.partition_id,
              project_id: pipeline.project_id,
              file_type: FILE_TYPE,
              file: carrierwave_file,
              size: variables_json.bytesize,
              file_format: :raw,
              locked: pipeline.locked
            )
          end

          private

          attr_reader :pipeline, :variables_attributes

          def carrierwave_file
            CarrierWaveStringFile.new_file(
              file_content: variables_json,
              filename: ::Ci::PipelineArtifact::DEFAULT_FILE_NAMES.fetch(FILE_TYPE),
              content_type: 'application/json'
            )
          end

          def variables_json
            Gitlab::Json.dump(variables.map(&:attributes))
          end
          strong_memoize_attr :variables_json

          def variables
            variables_attributes.map do |var_attrs|
              ::Ci::PipelineVariableItem.new(pipeline: pipeline, **var_attrs)
            end
          end
          strong_memoize_attr :variables
        end
      end
    end
  end
end
