module Gitlab
  module Ci
    ##
    # Base GitLab CI Configuration facade
    #
    class Config
      ##
      # Temporary delegations that should be removed after refactoring
      #
      delegate :before_script, to: :@global

      def initialize(config)
        @config = Loader.new(config).load!

        @global = Node::Global.new(@config)
        @global.process!
      end

      def valid?
        errors.none?
      end

      def errors
        @global.errors.map(&:to_s)
      end

      def to_hash
        @config
      end
    end
  end
end
