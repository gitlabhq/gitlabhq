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
      rescue Loader::FormatError, Extendable::ExtensionError => e
        raise Config::ConfigError, e.message
      rescue ::Gitlab::Ci::External::Processor::FileError => e
        raise ::Gitlab::Ci::YamlProcessor::ValidationError, e.message
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
        initial_config = Loader.new(config).load!
        project = opts.fetch(:project, nil)

        if project
          process_external_files(initial_config, project, opts)
        else
          initial_config
        end
      end

      def process_external_files(config, project, opts)
        sha = opts.fetch(:sha) { project.repository.root_ref_sha }
        ::Gitlab::Ci::External::Processor.new(config, project, sha).perform
      end
    end
  end
end
