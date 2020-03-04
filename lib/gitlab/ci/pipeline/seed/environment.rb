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
            job.project.environments
              .safe_find_or_create_by(name: expanded_environment_name)
          end

          private

          def expanded_environment_name
            job.expanded_environment_name
          end
        end
      end
    end
  end
end
