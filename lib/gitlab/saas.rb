# frozen_string_literal: true

# This module is used to return various SaaS related configurations
# which may be overridden in other variants of GitLab

module Gitlab
  module Saas
    def self.root_domain
      'gitlab.com'
    end

    def self.com_url
      'https://gitlab.com'
    end

    def self.staging_com_url
      'https://staging.gitlab.com'
    end

    def self.canary_toggle_com_url
      'https://next.gitlab.com'
    end

    def self.subdomain_regex
      %r{\Ahttps://[a-z0-9-]+\.gitlab\.com\z}
    end

    def self.dev_url
      'https://dev.gitlab.org'
    end

    def self.registry_prefix
      'registry.gitlab.com'
    end

    def self.customer_support_url
      'https://support.gitlab.com'
    end

    def self.customer_license_support_url
      'https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293'
    end

    def self.gitlab_com_status_url
      'https://status.gitlab.com'
    end

    def self.about_pricing_url
      "https://about.gitlab.com/pricing/"
    end

    def self.about_pricing_faq_url
      "https://about.gitlab.com/pricing#faq"
    end

    def self.about_feature_comparison_url
      "https://about.gitlab.com/pricing/gitlab-com/feature-comparison"
    end

    def self.doc_url
      'https://docs.gitlab.com'
    end

    def self.community_forum_url
      'https://forum.gitlab.com'
    end
  end
end

Gitlab::Saas.prepend_mod
