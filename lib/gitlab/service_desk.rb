# frozen_string_literal: true

module Gitlab
  module ServiceDesk
    # Check whether a project or GitLab instance can support the Service Desk
    # feature. Use `project.service_desk_enabled?` to check whether it is
    # enabled for a particular project.
    def self.enabled?(project:)
      supported? && project[:service_desk_enabled]
    end

    def self.supported?
      Gitlab::IncomingEmail.enabled? && Gitlab::IncomingEmail.supports_wildcard?
    end
  end
end
