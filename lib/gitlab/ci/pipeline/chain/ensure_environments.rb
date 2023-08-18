# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class EnsureEnvironments < Chain::Base
          def perform!
            pipeline.stages.map(&:statuses).flatten.each(&method(:ensure_environment))
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
