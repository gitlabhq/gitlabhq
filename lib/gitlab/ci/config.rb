module Gitlab
  module Ci
    ##
    # Base GitLab CI Configuration facade
    #
    class Config
      # EE would override this and utilize opts argument
      def initialize(config, opts = {})
        @config = Loader.new(config).load!

        @global = Entry::Global.new(@config)
        @global.compose!
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
    end
  end
end
