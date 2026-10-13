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
          optional :variables, type: Array, object_elements: true,
            desc: 'Array of variables to make available in the pipeline. If `variable_type` is omitted, it defaults ' \
              'to `env_var`.' do
            optional :key, type: String, desc: 'Key of the variable.', documentation: { example: 'UPLOAD_TO_S3' }
            optional :value, type: String, desc: 'Value of the variable.', documentation: { example: 'true' }
            optional :variable_type, type: String,
              values: ::Ci::PipelineVariable.variable_types.keys, default: 'env_var',
              desc: 'Type of the variable.'
          end
          optional :inputs, type: Hash, desc: 'Map of inputs, as key-value pairs, to use when creating the pipeline. ' \
                                          '[Generally ' \
                                          'available](https://gitlab.com/gitlab-org/gitlab/-/issues/536548) in ' \
                                          'GitLab 18.1. Feature flag `ci_inputs_for_pipelines` removed.'
        end
      end
    end
  end
end

API::Ci::Helpers::PipelinesHelpers.prepend_mod
