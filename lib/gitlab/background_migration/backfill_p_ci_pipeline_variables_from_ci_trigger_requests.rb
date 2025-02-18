# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPCiPipelineVariablesFromCiTriggerRequests < BatchedMigrationJob
      operation_name :backfill_p_ci_pipeline_variables_from_ci_trigger_requests
      feature_category :continuous_integration

      UNIQUE_BY = %i[pipeline_id key partition_id].freeze

      class CiPipelineVariable < ::Ci::ApplicationRecord
        self.table_name = :p_ci_pipeline_variables
        self.primary_key = :id

        attr_encrypted :value,
          mode: :per_attribute_iv_and_salt,
          insecure_mode: true,
          key: Settings.attr_encrypted_db_key_base,
          algorithm: 'aes-256-cbc'
      end

      class CiTriggerRequest < ::Ci::ApplicationRecord
        self.table_name = :ci_trigger_requests
        self.primary_key = :id

        serialize :variables
      end

      def perform
        each_sub_batch do |sub_batch|
          pipeline_variable_attributes =
            to_ci_pipeline_variable_attributes(sub_batch)
              .uniq { |attr| attr.slice(*UNIQUE_BY) }
              .map { |attr| CiPipelineVariable.new(attr).attributes }

          next if pipeline_variable_attributes.blank?

          CiPipelineVariable.upsert_all(pipeline_variable_attributes, unique_by: UNIQUE_BY, on_duplicate: :skip)
        end
      end

      private

      def to_ci_pipeline_variable_attributes(sub_batch)
        sub_batch
          .joins('INNER JOIN p_ci_pipelines ON p_ci_pipelines.id = ci_trigger_requests.commit_id')
          .where.not(variables: nil)
          .pluck(
            'p_ci_pipelines.id', 'p_ci_pipelines.partition_id', 'p_ci_pipelines.project_id',
            'ci_trigger_requests.variables'
          )
          .flat_map do |(pipeline_id, partition_id, project_id, variables)|
            deserialize(variables)
            .map do |key, value|
              {
                project_id: project_id,
                pipeline_id: pipeline_id,
                partition_id: partition_id,
                key: key,
                value: value
              }
            end
          end
      end

      def deserialize(variables)
        CiTriggerRequest.type_for_attribute('variables').deserialize(variables)
      end
    end
  end
end
