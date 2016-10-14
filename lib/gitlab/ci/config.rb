module Gitlab
  module Ci
    ##
    # Base GitLab CI Configuration facade
    #
    class Config
      ##
      # Temporary delegations that should be removed after refactoring
      #
      delegate :before_script, :image, :services, :after_script, :variables,
               :stages, :cache, :jobs, to: :@global

      def initialize(config)
        @config = Loader.new(config).load!

        @global = Node::Global.new(@config)
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
    end
  end
end
