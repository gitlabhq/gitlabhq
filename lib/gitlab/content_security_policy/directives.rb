# frozen_string_literal: true

# This module is used to return various SaaS related
# ContentSecurityPolicy Directives src which may be
# overridden in other variants of GitLab

module Gitlab
  module ContentSecurityPolicy
    module Directives
      def self.frame_src
        "https://www.google.com/recaptcha/ https://www.recaptcha.net/ https://content.googleapis.com https://content-compute.googleapis.com https://content-cloudbilling.googleapis.com https://content-cloudresourcemanager.googleapis.com"
      end

      def self.script_src
        "'strict-dynamic' 'self' 'unsafe-inline' 'unsafe-eval' https://www.google.com/recaptcha/ https://www.recaptcha.net https://apis.google.com"
      end
    end
  end
end

Gitlab::ContentSecurityPolicy::Directives.prepend_mod
