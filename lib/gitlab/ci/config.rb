module Gitlab
  module Ci
    class Config
      class LoaderError < StandardError; end

      delegate :valid?, :errors, to: :@global

      ##
      # Temporary delegations that should be removed after refactoring
      #
      delegate :before_script, to: :@global

      def initialize(config)
        loader = Loader.new(config)

        unless loader.valid?
          raise LoaderError, 'Invalid configuration format!'
        end

        @config = loader.load
        @global = Node::Global.new(@config)
        @global.process!
      end

      def to_hash
        @config
      end
    end
  end
end
