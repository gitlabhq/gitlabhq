# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        class Context
          include Gitlab::Utils::StrongMemoize

          TimeoutError = Class.new(StandardError)

          TEMP_MAX_INCLUDES = 100 # For logging; to be removed in https://gitlab.com/gitlab-org/gitlab/-/issues/396776

          include ::Gitlab::Utils::StrongMemoize

          attr_reader :project, :sha, :user, :parent_pipeline, :variables, :pipeline_config
          attr_reader :expandset, :execution_deadline, :logger, :max_includes

          delegate :instrument, to: :logger

          def initialize(
            project: nil, sha: nil, user: nil, parent_pipeline: nil, variables: nil,
            pipeline_config: nil, logger: nil
          )
            @project = project
            @sha = sha
            @user = user
            @parent_pipeline = parent_pipeline
            @variables = variables || Ci::Variables::Collection.new
            @pipeline_config = pipeline_config
            @expandset = []
            @execution_deadline = 0
            @logger = logger || Gitlab::Ci::Pipeline::Logger.new(project: project)
            @max_includes = Gitlab::CurrentSettings.current_application_settings.ci_max_includes
            yield self if block_given?
          end

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

          def mutate(attrs = {})
            self.class.new(**attrs) do |ctx|
              ctx.expandset = expandset
              ctx.execution_deadline = execution_deadline
              ctx.logger = logger
              ctx.max_includes = max_includes
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

          attr_writer :expandset, :execution_deadline, :logger, :max_includes

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
