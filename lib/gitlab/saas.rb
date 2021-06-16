# frozen_string_literal: true

# This module is used to return various SaaS related configurations
# which may be overridden in other variants of GitLab

module Gitlab
  module Saas
    def self.com_url
      'https://gitlab.com'
    end

    def self.staging_com_url
      'https://staging.gitlab.com'
    end

    def self.subdomain_regex
      %r{\Ahttps://[a-z0-9]+\.gitlab\.com\z}.freeze
    end

    def self.dev_url
      'https://dev.gitlab.org'
    end
  end
end

Gitlab::Saas.prepend_mod
