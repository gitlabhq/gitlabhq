module EE
  module Gitlab
    module ServiceDesk
      def self.enabled?
        ::License.current &&
          ::License.current.add_on?('GitLab_ServiceDesk') &&
          ::Gitlab::IncomingEmail.enabled? &&
          ::Gitlab::IncomingEmail.supports_wildcard?
      end
    end
  end
end
