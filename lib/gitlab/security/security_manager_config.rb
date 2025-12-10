# frozen_string_literal: true

module Gitlab
  module Security
    class SecurityManagerConfig
      def self.enabled?
        ENV.fetch('GITLAB_SECURITY_MANAGER_ROLE', 'false').downcase.in?(%w[true 1 yes on enabled])
      end
    end
  end
end
