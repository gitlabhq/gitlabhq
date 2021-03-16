# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Seed
        class Environment < Seed::Base
          attr_reader :job

          def initialize(job)
            @job = job
          end

          def to_resource
            environments.safe_find_or_create_by(name: expanded_environment_name) do |environment|
              # Initialize the attributes at creation
              environment.auto_stop_in = auto_stop_in
              environment.tier = deployment_tier
            end
          end

          private

          def environments
            job.project.environments
          end

          def auto_stop_in
            job.environment_auto_stop_in
          end

          def deployment_tier
            job.environment_deployment_tier
          end

          def expanded_environment_name
            job.expanded_environment_name
          end
        end
      end
    end
  end
end
