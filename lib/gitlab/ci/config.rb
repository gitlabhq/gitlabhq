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

      attr_reader :root, :context, :source_ref_path, :source

      def initialize(config, project: nil, sha: nil, user: nil, parent_pipeline: nil, source_ref_path: nil, source: nil)
        @context = build_context(project: project, sha: sha, user: user, parent_pipeline: parent_pipeline, ref: source_ref_path)
        @context.set_deadline(TIMEOUT_SECONDS)

        @source_ref_path = source_ref_path
        @source = source

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
        initial_config = Config::Yaml.load!(config)
        initial_config = Config::External::Processor.new(initial_config, @context).perform
        initial_config = Config::Extendable.new(initial_config).to_hash
        initial_config = Config::Yaml::Tags::Resolver.new(initial_config).to_hash
        Config::EdgeStagesInjector.new(initial_config).to_hash
      end

      def find_sha(project)
        branches = project&.repository&.branches || []

        unless branches.empty?
          project.repository.root_ref_sha
        end
      end

      def build_context(project:, sha:, user:, parent_pipeline:, ref:)
        Config::External::Context.new(
          project: project,
          sha: sha || find_sha(project),
          user: user,
          parent_pipeline: parent_pipeline,
          variables: build_variables(project: project, ref: ref))
      end

      def build_variables(project:, ref:)
        Gitlab::Ci::Variables::Collection.new.tap do |variables|
          break variables unless project

          # The order of the following lines is important as priority of CI variables is
          # defined globally within GitLab.
          #
          # See more detail in the docs: https://docs.gitlab.com/ee/ci/variables/#cicd-variable-precedence
          variables.concat(project.predefined_variables)
          variables.concat(pipeline_predefined_variables(ref: ref))
          variables.concat(project.ci_instance_variables_for(ref: ref))
          variables.concat(project.group.ci_variables_for(ref, project)) if project.group
          variables.concat(project.ci_variables_for(ref: ref))
        end
      end

      # https://gitlab.com/gitlab-org/gitlab/-/issues/337633 aims to add all predefined variables
      # to this list, but only CI_COMMIT_REF_NAME is available right now to support compliance pipelines.
      def pipeline_predefined_variables(ref:)
        Gitlab::Ci::Variables::Collection.new.tap do |v|
          v.append(key: 'CI_COMMIT_REF_NAME', value: ref)
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
