# frozen_string_literal: true

module Gitlab
  module ServiceDesk
    def self.enabled?(project)
      supported? && project.service_desk_enabled
    end

    def self.supported?
      Gitlab::Email::IncomingEmail.enabled? && Gitlab::Email::IncomingEmail.supports_wildcard?
    end
  end
end
