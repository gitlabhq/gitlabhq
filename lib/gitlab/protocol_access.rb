module Gitlab
  module ProtocolAccess
    def self.allowed?(protocol)
      if protocol == 'web'
        true
      elsif current_application_settings.enabled_git_access_protocol.blank?
        true
      else
        protocol == current_application_settings.enabled_git_access_protocol
      end
    end
  end
end
