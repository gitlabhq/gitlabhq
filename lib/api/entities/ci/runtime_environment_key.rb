# frozen_string_literal: true

module API
  module Entities
    module Ci
      class RuntimeEnvironmentKey < Grape::Entity
        expose(
          :runtime_environment_key,
          documentation: { type: 'String', example: '42/s_machineid/data' }
        ) do |build|
          build.job_runtime_environment&.runtime_environment&.environment_key
        end
      end
    end
  end
end
