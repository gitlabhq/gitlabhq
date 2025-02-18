# frozen_string_literal: true

module Gitlab
  module Ci
    #
    # Base GitLab CI Configuration facade
    #
    class Config
      include Gitlab::Utils::StrongMemoize

      ConfigError = Class.new(StandardError)
      TIMEOUT_SECONDS = ENV.fetch('GITLAB_CI_CONFIG_FETCH_TIMEOUT_SECONDS', 30).to_i.clamp(0, 60).seconds
      TIMEOUT_MESSAGE = 'Request timed out when fetching configuration files.'

      RESCUE_ERRORS = [
        Gitlab::Config::Loader::FormatError,
        Extendable::ExtensionError,
        External::Processor::IncludeError,
        Config::Yaml::Tags::TagError
      ].freeze

      attr_reader :root, :context, :source_ref_path, :source, :logger, :inject_edge_stages, :pipeline_policy_context

      # rubocop: disable Metrics/ParameterLists
      def initialize(config, project: nil, pipeline: nil, sha: nil, ref: nil, user: nil, parent_pipeline: nil, source: nil, pipeline_config: nil, logger: nil, inject_edge_stages: true, pipeline_policy_context: nil)
        @logger = logger || ::Gitlab::Ci::Pipeline::Logger.new(project: project)
        @source_ref_path = pipeline&.source_ref_path
        @project = project
        @inject_edge_stages = inject_edge_stages
        @pipeline_policy_context = pipeline_policy_context

        @context = self.logger.instrument(:config_build_context, once: true) do
          pipeline ||= ::Ci::Pipeline.new(project: project, sha: sha, ref: ref, user: user, source: source)

          build_context(project: project, pipeline: pipeline, sha: sha, user: user, parent_pipeline: parent_pipeline, pipeline_config: pipeline_config, pipeline_policy_context: pipeline_policy_context)
        end

        @context.set_deadline(TIMEOUT_SECONDS)

        @source = source

        Gitlab::Ci::Config::FeatureFlags.with_actor(project) do
          @config = self.logger.instrument(:config_expand, once: true) do
            expand_config(config)
          end

          @root = self.logger.instrument(:config_root, once: true) do
            Entry::Root.new(@config, project: project, user: user, logger: self.logger)
          end

          self.logger.instrument(:config_root_compose, once: true) do
            @root.compose!
          end
        end
      rescue *rescue_errors => e
        raise Config::ConfigError, e.message
      end
      # rubocop: enable Metrics/ParameterLists

      def valid?
        @root.valid?
      end

      def errors
        @root.errors
      end

      def warnings
        @root.warnings
      end

      def to_hash
        @config
      end

      ##
      # Temporary method that should be removed after refactoring
      #
      # rubocop:disable Gitlab/NoCodeCoverageComment -- This is an existing method and probably never called
      # :nocov:
      def variables
        Gitlab::Ci::Config::FeatureFlags.with_actor(@project) do
          root.variables_value
        end
      end
      # rubocop:enable Gitlab/NoCodeCoverageComment

      def variables_with_data
        Gitlab::Ci::Config::FeatureFlags.with_actor(@project) do
          root.variables_entry.value_with_data
        end
      end

      def variables_with_prefill_data
        Gitlab::Ci::Config::FeatureFlags.with_actor(@project) do
          root.variables_entry.value_with_prefill_data
        end
      end

      def stages
        Gitlab::Ci::Config::FeatureFlags.with_actor(@project) do
          root.stages_value
        end
      end

      def jobs
        Gitlab::Ci::Config::FeatureFlags.with_actor(@project) do
          root.jobs_value
        end
      end

      def workflow_rules
        Gitlab::Ci::Config::FeatureFlags.with_actor(@project) do
          root.workflow_entry.rules_value
        end
      end

      def workflow_name
        Gitlab::Ci::Config::FeatureFlags.with_actor(@project) do
          root.workflow_entry.name
        end
      end

      def workflow_auto_cancel
        Gitlab::Ci::Config::FeatureFlags.with_actor(@project) do
          root.workflow_entry.auto_cancel_value
        end
      end

      def normalized_jobs
        @normalized_jobs ||= Ci::Config::Normalizer.new(jobs).normalize_jobs
      end

      def included_templates
        @context.includes.filter_map { |i| i[:location] if i[:type] == :template }
      end

      def included_components
        @context.includes.filter_map { |i| i[:component] if i[:type] == :component }.uniq
      end

      def metadata
        {
          includes: @context.includes,
          merged_yaml: @config&.deep_stringify_keys&.to_yaml
        }
      end

      private

      def expand_config(config)
        build_config(config)

      rescue Gitlab::Config::Loader::Yaml::DataTooLargeError => e
        track_and_raise_for_dev_exception(e)
        raise Config::ConfigError, e.message

      rescue Gitlab::Ci::Config::External::Context::TimeoutError => e
        track_and_raise_for_dev_exception(e)
        raise Config::ConfigError, TIMEOUT_MESSAGE
      end

      def build_config(config)
        initial_config = logger.instrument(:config_yaml_load, once: true) do
          Config::Yaml.load!(config)
        end

        initial_config = logger.instrument(:config_external_process, once: true) do
          Config::External::Processor.new(initial_config, @context).perform
        end

        initial_config = logger.instrument(:config_yaml_extend, once: true) do
          Config::Extendable.new(initial_config).to_hash
        end

        initial_config = logger.instrument(:config_tags_resolve, once: true) do
          Config::Yaml::Tags::Resolver.new(initial_config).to_hash
        end

        return initial_config unless inject_edge_stages

        logger.instrument(:config_stages_inject, once: true) do
          Config::EdgeStagesInjector.new(initial_config).to_hash
        end
      end

      def find_sha(project)
        branches = project&.repository&.branches || []

        unless branches.empty?
          project.repository.root_ref_sha
        end
      end

      def build_context(project:, pipeline:, sha:, user:, parent_pipeline:, pipeline_config:, pipeline_policy_context:)
        Config::External::Context.new(
          project: project,
          pipeline: pipeline,
          sha: sha || find_sha(project),
          user: user,
          parent_pipeline: parent_pipeline,
          variables: build_variables(pipeline: pipeline),
          pipeline_config: pipeline_config,
          pipeline_policy_context: pipeline_policy_context,
          logger: logger)
      end

      def build_variables(pipeline:)
        logger.instrument(:config_build_variables, once: true) do
          pipeline
            .variables_builder
            .config_variables
        end
      end

      def track_and_raise_for_dev_exception(error)
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(error, @context.sentry_payload)
      end

      # Overridden in EE
      def rescue_errors
        RESCUE_ERRORS
      end
    end
  end
end

Gitlab::Ci::Config.prepend_mod_with('Gitlab::Ci::ConfigEE')
