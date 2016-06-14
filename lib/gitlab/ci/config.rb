module Gitlab
  module Ci
    ##
    # Base GitLab CI Configuration facade
    #
    class Config
      delegate :valid?, :errors, to: :@global

      ##
      # Temporary delegations that should be removed after refactoring
      #
      delegate :before_script, to: :@global

      def initialize(config)
        @config = Loader.new(config).load!

        @global = Node::Global.new(@config)
        @global.process!
      end

      def to_hash
        @config
      end
    end
  end
end
