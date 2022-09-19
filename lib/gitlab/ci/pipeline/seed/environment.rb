# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Seed
        class Environment < Seed::Base
          attr_reader :job, :merge_request

          delegate :simple_variables, to: :job

          def initialize(job, merge_request: nil)
            @job = job
            @merge_request = merge_request
          end

          def to_resource
            environments.safe_find_or_create_by(name: expanded_environment_name) do |environment|
              # Initialize the attributes at creation
              environment.auto_stop_in = expanded_auto_stop_in
              environment.tier = deployment_tier
              environment.merge_request = merge_request
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
            job.environment_tier_from_options
          end

          def expanded_environment_name
            job.expanded_environment_name
          end

          def expanded_auto_stop_in
            return unless auto_stop_in

            ExpandVariables.expand(auto_stop_in, -> { simple_variables.sort_and_expand_all })
          end
        end
      end
    end
  end
end
