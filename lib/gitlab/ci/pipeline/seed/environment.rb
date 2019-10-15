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
            find_environment || ::Environment.new(attributes)
          end

          private

          def find_environment
            job.project.environments.find_by_name(expanded_environment_name)
          end

          def expanded_environment_name
            job.expanded_environment_name
          end

          def attributes
            {
              project: job.project,
              name: expanded_environment_name
            }
          end
        end
      end
    end
  end
end
