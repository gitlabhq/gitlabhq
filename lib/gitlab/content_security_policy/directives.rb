# frozen_string_literal: true

# This module is used to return various SaaS related
# ContentSecurityPolicy Directives src which may be
# overridden in other variants of GitLab

module Gitlab
  module ContentSecurityPolicy
    module Directives
      def self.connect_src
        "'self'"
      end

      def self.frame_src
        "https://www.google.com/recaptcha/ https://www.recaptcha.net/ https://www.googletagmanager.com/ns.html"
      end

      def self.script_src
        "'strict-dynamic' 'self' 'unsafe-inline' 'unsafe-eval' https://www.google.com/recaptcha/ https://www.recaptcha.net"
      end

      def self.style_src
        "'self' 'unsafe-inline'"
      end
    end
  end
end

Gitlab::ContentSecurityPolicy::Directives.prepend_mod
