# frozen_string_literal: true

module API
  module Entities
    module Ci
      module Lint
        class Result < Grape::Entity
          expose :valid?, as: :valid, documentation: { type: 'boolean' }
          expose :errors, documentation: { is_array: true, type: 'string',
                                           example: 'variables config should be a hash of key value pairs' }
          expose :warnings, documentation: { is_array: true, type: 'string',
                                             example: 'jobs:job may allow multiple pipelines ...' }
          expose :merged_yaml, documentation: { type: 'string', example: '---\n:another_test:\n  :stage: test\n
          :script: echo 2\n:test:\n  :stage: test\n  :script: echo 1\n' }
          expose :includes, using: Entities::Ci::Lint::Result::Include,
            documentation: { is_array: true, type: 'object', example: '{ "blob": "https://gitlab.com/root/example-project/-/blob/...' }
          expose :jobs, if: ->(result, options) { options[:include_jobs] },
            documentation: { is_array: true, type: 'object', example: '{ "name": "test: .... }' }
        end
      end
    end
  end
end
