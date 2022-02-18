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
        External::Processor::IncludeError,
        Config::Yaml::Tags::TagError
      ].freeze

      attr_reader :root, :context, :source_ref_path, :source, :logger

      def initialize(config, project: nil, pipeline: nil, sha: nil, user: nil, parent_pipeline: nil, source: nil, logger: nil)
        @logger = logger || ::Gitlab::Ci::Pipeline::Logger.new(project: project)
        @source_ref_path = pipeline&.source_ref_path

        @context = self.logger.instrument(:config_build_context) do
          build_context(project: project, pipeline: pipeline, sha: sha, user: user, parent_pipeline: parent_pipeline)
        end

        @context.set_deadline(TIMEOUT_SECONDS)

        @source = source

        @config = self.logger.instrument(:config_expand) do
          expand_config(config)
        end

        @root = self.logger.instrument(:config_compose) do
          Entry::Root.new(@config, project: project, user: user).tap(&:compose!)
        end
      rescue *rescue_errors => e
        raise Config::ConfigError, e.message
      end

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
      def variables
        root.variables_value
      end

      def variables_with_data
        root.variables_entry.value_with_data
      end

      def stages
        root.stages_value
      end

      def jobs
        root.jobs_value
      end

      def normalized_jobs
        @normalized_jobs ||= Ci::Config::Normalizer.new(jobs).normalize_jobs
      end

      def included_templates
        @context.expandset.filter_map { |i| i[:template] }
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
        initial_config = logger.instrument(:config_yaml_load) do
          Config::Yaml.load!(config)
        end

        initial_config = logger.instrument(:config_external_process) do
          Config::External::Processor.new(initial_config, @context).perform
        end

        initial_config = logger.instrument(:config_yaml_extend) do
          Config::Extendable.new(initial_config).to_hash
        end

        initial_config = logger.instrument(:config_tags_resolve) do
          Config::Yaml::Tags::Resolver.new(initial_config).to_hash
        end

        logger.instrument(:config_stages_inject) do
          Config::EdgeStagesInjector.new(initial_config).to_hash
        end
      end

      def find_sha(project)
        branches = project&.repository&.branches || []

        unless branches.empty?
          project.repository.root_ref_sha
        end
      end

      def build_context(project:, pipeline:, sha:, user:, parent_pipeline:)
        Config::External::Context.new(
          project: project,
          sha: sha || find_sha(project),
          user: user,
          parent_pipeline: parent_pipeline,
          variables: build_variables(project: project, pipeline: pipeline),
          logger: logger)
      end

      def build_variables(project:, pipeline:)
        logger.instrument(:config_build_variables) do
          build_variables_without_instrumentation(
            project: project,
            pipeline: pipeline
          )
        end
      end

      def build_variables_without_instrumentation(project:, pipeline:)
        Gitlab::Ci::Variables::Collection.new.tap do |variables|
          break variables unless project

          # The order of the following lines is important as priority of CI variables is
          # defined globally within GitLab.
          #
          # See more detail in the docs: https://docs.gitlab.com/ee/ci/variables/#cicd-variable-precedence
          variables.concat(project.predefined_variables)
          variables.concat(pipeline.predefined_variables) if pipeline
          variables.concat(secret_variables(project: project, pipeline: pipeline))
          variables.concat(project.group.ci_variables_for(source_ref_path, project)) if project.group
          variables.concat(project.ci_variables_for(ref: source_ref_path))
          variables.concat(pipeline.variables) if pipeline
          variables.concat(pipeline.pipeline_schedule.job_variables) if pipeline&.pipeline_schedule
        end
      end

      def secret_variables(project:, pipeline:)
        if pipeline
          pipeline.variables_builder.secret_instance_variables
        else
          Gitlab::Ci::Variables::Builder::Instance.new.secret_variables
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
