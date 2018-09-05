module Gitlab
  module Ci
    #
    # Base GitLab CI Configuration facade
    #
    class Config
      prepend EE::Gitlab::Ci::Config

      ConfigError = Class.new(StandardError)

      def initialize(config, opts = {})
        @config = Config::Extendable
          .new(build_config(config, opts))
          .to_hash

        @global = Entry::Global.new(@config)
        @global.compose!
      rescue Loader::FormatError, Extendable::ExtensionError => e
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

      # 'opts' argument is used in EE see /ee/lib/ee/gitlab/ci/config.rb
      def build_config(config, opts = {})
        Loader.new(config).load!
      end
    end
  end
end
