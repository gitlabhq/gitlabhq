# frozen_string_literal: true

module API
  module Ci
    module Helpers
      module PipelinesHelpers
        extend ActiveSupport::Concern
        extend Grape::API::Helpers

        params :optional_scope do
          optional :scope, types: [String, Array[String]], desc: 'The scope of builds to show',
            values: ::CommitStatus::AVAILABLE_STATUSES,
            coerce_with: ->(scope) {
                           case scope
                           when String
                             [scope]
                           when ::Array
                             scope
                           else
                             ['unknown']
                           end
                         },
            documentation: { example: %w[pending running] }
        end

        params :create_pipeline_params do
          requires :ref, type: String, desc: 'Reference',
            documentation: { example: 'develop' }
          optional :variables, type: Array, desc: 'Array of variables available in the pipeline' do
            optional :key, type: String, desc: 'The key of the variable', documentation: { example: 'UPLOAD_TO_S3' }
            optional :value, type: String, desc: 'The value of the variable', documentation: { example: 'true' }
            optional :variable_type, type: String,
              values: ::Ci::PipelineVariable.variable_types.keys, default: 'env_var',
              desc: 'The type of variable, must be one of env_var or file. Defaults to env_var'
          end
        end
      end
    end
  end
end

API::Ci::Helpers::PipelinesHelpers.prepend_mod
