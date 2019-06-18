# frozen_string_literal: true

module Gitlab
  module Ci
    #
    # Base GitLab CI Configuration facade
    #
    class Config
      ConfigError = Class.new(StandardError)

      RESCUE_ERRORS = [
        Gitlab::Config::Loader::FormatError,
        Extendable::ExtensionError,
        External::Processor::IncludeError
      ].freeze

      attr_reader :root

      def initialize(config, project: nil, sha: nil, user: nil)
        @config = Config::Extendable
          .new(build_config(config, project: project, sha: sha, user: user))
          .to_hash

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

      def build_config(config, project:, sha:, user:)
        initial_config = Gitlab::Config::Loader::Yaml.new(config).load!

        process_external_files(initial_config, project: project, sha: sha, user: user)
      end

      def process_external_files(config, project:, sha:, user:)
        Config::External::Processor.new(config,
          project: project,
          sha: sha || project&.repository&.root_ref_sha,
          user: user,
          expandset: Set.new).perform
      end

      # Overriden in EE
      def rescue_errors
        RESCUE_ERRORS
      end
    end
  end
end
