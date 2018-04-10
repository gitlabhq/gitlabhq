module Gitlab
  module ProtocolAccess
    def self.allowed?(protocol)
      if protocol == 'web'
        true
      elsif Gitlab::CurrentSettings.enabled_git_access_protocol.blank?
        true
      else
        protocol == Gitlab::CurrentSettings.enabled_git_access_protocol
      end
    end
  end
end
