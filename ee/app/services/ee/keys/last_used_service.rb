module EE
  module Keys
    module LastUsedService
      def update?
        raise NotImplementedError unless defined?(super)

        !::Gitlab::Geo.secondary? && super
      end
    end
  end
end
