module EE
  module Gitlab
    module Database
      def self.readonly?
        raise NotImplementedError unless defined?(super)

        Gitlab::Geo.secondary? || super
      end
    end
  end
end
