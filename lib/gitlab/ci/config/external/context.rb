# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        class Context
          TimeoutError = Class.new(StandardError)

          attr_reader :project, :sha, :user, :parent_pipeline
          attr_reader :expandset, :execution_deadline

          def initialize(project: nil, sha: nil, user: nil, parent_pipeline: nil)
            @project = project
            @sha = sha
            @user = user
            @parent_pipeline = parent_pipeline
            @expandset = Set.new
            @execution_deadline = 0

            yield self if block_given?
          end

          def mutate(attrs = {})
            self.class.new(**attrs) do |ctx|
              ctx.expandset = expandset
              ctx.execution_deadline = execution_deadline
            end
          end

          def set_deadline(timeout_seconds)
            @execution_deadline = current_monotonic_time + timeout_seconds.to_f
          end

          def check_execution_time!
            raise TimeoutError if execution_expired?
          end

          def sentry_payload
            {
              user: user.inspect,
              project: project.inspect
            }
          end

          protected

          attr_writer :expandset, :execution_deadline

          private

          def current_monotonic_time
            Gitlab::Metrics::System.monotonic_time
          end

          def execution_expired?
            return false if execution_deadline == 0

            current_monotonic_time > execution_deadline
          end
        end
      end
    end
  end
end
