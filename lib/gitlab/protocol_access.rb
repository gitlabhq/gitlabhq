module Gitlab
  module ProtocolAccess
    def self.allowed?(protocol)
      if protocol.to_s == 'web'
        true
      elsif !current_application_settings.enabled_git_access_protocols.present?
        true
      else
        protocol.to_s == current_application_settings.enabled_git_access_protocols
      end
    end
  end
end
