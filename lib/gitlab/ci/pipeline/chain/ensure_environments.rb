# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class EnsureEnvironments < Chain::Base
          def perform!
            pipeline.stages.flat_map(&:statuses).each do |job|
              next unless job.is_a?(::Ci::Processable) && job.has_environment_keyword?

              ensure_environment(job)
            end
          end

          def break?
            false
          end

          private

          def ensure_environment(build)
            ::Environments::CreateForJobService.new.execute(build)
          end
        end
      end
    end
  end
end
