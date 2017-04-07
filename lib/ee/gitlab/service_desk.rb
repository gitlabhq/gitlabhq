module EE
  module Gitlab
    module ServiceDesk
      def self.enabled?
        ::License.current && ::License.current.add_on?('GitLab_ServiceDesk')
      end
    end
  end
end
