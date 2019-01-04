# frozen_string_literal: true

module Gitlab
  module Ci
    #
    # Base GitLab CI Configuration facade
    #
    class Config
      ConfigError = Class.new(StandardError)

      def initialize(config, opts = {})
        @config = Config::Extendable
          .new(build_config(config, opts))
          .to_hash

        @global = Entry::Global.new(@config)
        @global.compose!
      rescue Gitlab::Config::Loader::FormatError,
             Extendable::ExtensionError,
             External::Processor::IncludeError => e
        raise Config::ConfigError, e.message
      end

      def valid?
        @global.valid?
      end

      def errors
        @global.errors
      end

      def to_hash
        @config
      end

      ##
      # Temporary method that should be removed after refactoring
      #
      def before_script
        @global.before_script_value
      end

      def image
        @global.image_value
      end

      def services
        @global.services_value
      end

      def after_script
        @global.after_script_value
      end

      def variables
        @global.variables_value
      end

      def stages
        @global.stages_value
      end

      def cache
        @global.cache_value
      end

      def jobs
        @global.jobs_value
      end

      private

      def build_config(config, opts = {})
        initial_config = Gitlab::Config::Loader::Yaml.new(config).load!
        project = opts.fetch(:project, nil)

        if project
          process_external_files(initial_config, project, opts)
        else
          initial_config
        end
      end

      def process_external_files(config, project, opts)
        sha = opts.fetch(:sha) { project.repository.root_ref_sha }
        Config::External::Processor.new(config, project: project, sha: sha).perform
      end
    end
  end
end
