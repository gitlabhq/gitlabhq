# frozen_string_literal: true

module Gitlab
  module LetsEncrypt
    def self.enabled?(pages_domain = nil)
      return false unless Gitlab::CurrentSettings.lets_encrypt_terms_of_service_accepted

      return false unless Feature.enabled?(:pages_auto_ssl)

      # If no domain is passed, just check whether we're enabled globally
      return true unless pages_domain

      !!pages_domain.project && Feature.enabled?(:pages_auto_ssl_for_project, pages_domain.project)
    end
  end
end
