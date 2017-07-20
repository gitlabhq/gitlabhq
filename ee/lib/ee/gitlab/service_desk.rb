module EE
  module Gitlab
    module ServiceDesk
      # Check whether a project or GitLab instance can support the Service Desk
      # feature. Use `project.service_desk_enabled?` to check whether it is
      # enabled for a particular project.
      def self.enabled?(project: nil)
        return unless ::Gitlab::IncomingEmail.enabled? && ::Gitlab::IncomingEmail.supports_wildcard?

        (project || ::License).feature_available?(:service_desk)
      end
    end
  end
end
