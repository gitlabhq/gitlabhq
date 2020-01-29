# frozen_string_literal: true

csp_settings = Settings.gitlab.content_security_policy

if csp_settings['enabled']
  # See https://guides.rubyonrails.org/security.html#content-security-policy
  Rails.application.config.content_security_policy do |policy|
    directives = csp_settings.fetch('directives', {})
    loader = ::Gitlab::ContentSecurityPolicy::ConfigLoader.new(directives)
    loader.load(policy)
  end

  Rails.application.config.content_security_policy_report_only = csp_settings['report_only']
  Rails.application.config.content_security_policy_nonce_generator = ->(request) { SecureRandom.base64(16) }
  Rails.application.config.content_security_policy_nonce_directives = %w(script-src)
end
