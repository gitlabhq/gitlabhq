module EE
  module Gitlab
    module Database
      def self.read_only?
        raise NotImplementedError unless defined?(super)

        Gitlab::Geo.secondary? || super
      end
    end
  end
end
