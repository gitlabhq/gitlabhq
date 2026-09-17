# frozen_string_literal: true

module Gitlab
  module Security
    class SecurityManagerConfig
      # The Security Manager role is generally available and no longer gated.
      # This class is retained only until its remaining call sites are removed.
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/584144
      def self.enabled?
        true
      end
    end
  end
end
