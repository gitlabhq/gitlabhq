module Gitlab
  module Ci
    class Config
      class LoaderError < StandardError; end

      def initialize(config)
        loader = Loader.new(config)
        @config = loader.load!
      end

      def to_hash
        @config
      end
    end
  end
end
