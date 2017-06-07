module EE
  module Gitlab
    module ServiceDesk
      def self.enabled?
        ::License.current&.feature_available?(:service_desk) &&
          ::Gitlab::IncomingEmail.enabled? &&
          ::Gitlab::IncomingEmail.supports_wildcard?
      end
    end
  end
end
