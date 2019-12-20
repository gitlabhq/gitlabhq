# frozen_string_literal: true

module Gitlab
  module Ci
    #
    # Base GitLab CI Configuration facade
    #
    class Config
      ConfigError = Class.new(StandardError)
      TIMEOUT_SECONDS = 30.seconds
      TIMEOUT_MESSAGE = 'Resolving config took longer than expected'

      RESCUE_ERRORS = [
        Gitlab::Config::Loader::FormatError,
        Extendable::ExtensionError,
        External::Processor::IncludeError
      ].freeze

      attr_reader :root

      def initialize(config, project: nil, sha: nil, user: nil)
        @context = build_context(project: project, sha: sha, user: user)

        if Feature.enabled?(:ci_limit_yaml_expansion, project, default_enabled: true)
          @context.set_deadline(TIMEOUT_SECONDS)
        end

        @config = expand_config(config)

        @root = Entry::Root.new(@config)
        @root.compose!

      rescue *rescue_errors => e
        raise Config::ConfigError, e.message
      end

      def valid?
        @root.valid?
      end

      def errors
        @root.errors
      end

      def to_hash
        @config
      end

      ##
      # Temporary method that should be removed after refactoring
      #
      def variables
        root.variables_value
      end

      def stages
        root.stages_value
      end

      def jobs
        root.jobs_value
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
        initial_config = Gitlab::Config::Loader::Yaml.new(config).load!
        initial_config = Config::External::Processor.new(initial_config, @context).perform
        initial_config = Config::Extendable.new(initial_config).to_hash

        if Feature.enabled?(:ci_pre_post_pipeline_stages, @context.project, default_enabled: true)
          initial_config = Config::EdgeStagesInjector.new(initial_config).to_hash
        end

        initial_config
      end

      def build_context(project:, sha:, user:)
        Config::External::Context.new(
          project: project,
          sha: sha || project&.repository&.root_ref_sha,
          user: user)
      end

      def track_and_raise_for_dev_exception(error)
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(error, @context.sentry_payload)
      end

      # Overriden in EE
      def rescue_errors
        RESCUE_ERRORS
      end
    end
  end
end

Gitlab::Ci::Config.prepend_if_ee('EE::Gitlab::Ci::ConfigEE')
