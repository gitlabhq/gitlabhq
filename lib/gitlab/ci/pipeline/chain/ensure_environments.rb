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
            return unless build.instance_of?(::Ci::Build) && build.has_environment_keyword?

            environment = ::Gitlab::Ci::Pipeline::Seed::Environment
                            .new(build, merge_request: @command.merge_request)
                            .to_resource

            if environment.persisted?
              build.persisted_environment = environment
              build.assign_attributes(metadata_attributes: { expanded_environment_name: environment.name })
            else
              build.assign_attributes(status: :failed, failure_reason: :environment_creation_failure)
            end
          end
        end
      end
    end
  end
end
