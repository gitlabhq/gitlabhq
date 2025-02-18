# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        class Context
          include Gitlab::Utils::StrongMemoize

          TimeoutError = Class.new(StandardError)

          include ::Gitlab::Utils::StrongMemoize

          attr_reader :project, :sha, :user, :parent_pipeline, :variables, :pipeline_config, :parallel_requests,
            :pipeline, :expandset, :execution_deadline, :logger, :max_includes, :max_total_yaml_size_bytes,
            :pipeline_policy_context

          attr_accessor :total_file_size_in_bytes

          delegate :instrument, to: :logger

          # We try to keep the number of parallel HTTP requests to a minimum to avoid overloading IO.
          MAX_PARALLEL_REMOTE_REQUESTS = 4

          # rubocop:disable Metrics/ParameterLists -- all arguments needed
          def initialize(
            project: nil, pipeline: nil, sha: nil, user: nil, parent_pipeline: nil, variables: nil,
            pipeline_config: nil, logger: nil, pipeline_policy_context: nil
          )
            @project = project
            @pipeline = pipeline
            @sha = sha
            @user = user
            @parent_pipeline = parent_pipeline
            @variables = variables || Ci::Variables::Collection.new
            @pipeline_config = pipeline_config
            @pipeline_policy_context = pipeline_policy_context
            @expandset = []
            @parallel_requests = []
            @execution_deadline = 0
            @logger = logger || Gitlab::Ci::Pipeline::Logger.new(project: project)
            @max_includes = Gitlab::CurrentSettings.current_application_settings.ci_max_includes
            @max_total_yaml_size_bytes =
              Gitlab::CurrentSettings.current_application_settings.ci_max_total_yaml_size_bytes
            @total_file_size_in_bytes = 0
            yield self if block_given?
          end
          # rubocop:enable Metrics/ParameterLists

          def top_level_worktree_paths
            strong_memoize(:top_level_worktree_paths) do
              project.repository.tree(sha).blobs.map(&:path)
            end
          end

          def all_worktree_paths
            strong_memoize(:all_worktree_paths) do
              project.repository.ls_files(sha)
            end
          end

          def variables_hash
            strong_memoize(:variables_hash) do
              variables.to_hash
            end
          end

          def variables_hash_expanded
            strong_memoize(:variables_hash_expanded) do
              variables_sorted_and_expanded.to_hash
            end
          end

          def variables_sorted_and_expanded
            strong_memoize(:variables_sorted_and_expanded) do
              variables.sort_and_expand_all
            end
          end

          def mutate(attrs = {})
            self.class.new(**attrs) do |ctx|
              ctx.pipeline = pipeline
              ctx.expandset = expandset
              ctx.execution_deadline = execution_deadline
              ctx.logger = logger
              ctx.max_includes = max_includes
              ctx.max_total_yaml_size_bytes = max_total_yaml_size_bytes
              ctx.parallel_requests = parallel_requests
            end
          end

          def set_deadline(timeout_seconds)
            @execution_deadline = current_monotonic_time + timeout_seconds.to_f
          end

          def check_execution_time!
            raise TimeoutError if execution_expired?
          end

          def execute_remote_parallel_request(lazy_response)
            parallel_requests.delete_if(&:complete?)

            # We are "assuming" that the first request in the queue is the first one to complete.
            # This is good enough approximation.
            parallel_requests.first&.wait unless parallel_requests.size < MAX_PARALLEL_REMOTE_REQUESTS

            parallel_requests << lazy_response.execute
          end

          def sentry_payload
            {
              user: user.inspect,
              project: project.inspect
            }
          end

          def mask_variables_from(string)
            variables.reduce(string.dup) do |str, variable|
              if variable[:masked]
                Gitlab::Ci::MaskSecret.mask!(str, variable[:value])
              else
                str
              end
            end
          end

          def includes
            expandset.map(&:metadata)
          end

          # Some Ci::ProjectConfig sources prepend the config content with an "internal" `include`, which becomes
          # the first included file. When running a pipeline, we pass pipeline_config into the context of the first
          # included file, which we use in this method to determine if the file is an "internal" one.
          def internal_include?
            !!pipeline_config&.internal_include_prepended?
          end

          protected

          attr_writer :pipeline, :expandset, :execution_deadline, :logger, :max_includes, :max_total_yaml_size_bytes,
            :parallel_requests

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
