# frozen_string_literal: true

csp_settings = Settings.gitlab.content_security_policy

csp_settings['enabled'] = Gitlab::ContentSecurityPolicy::ConfigLoader.default_enabled if csp_settings['enabled'].nil?
csp_settings['report_only'] = false if csp_settings['report_only'].nil?
csp_settings['directives'] ||= {}

if csp_settings['enabled']
  # See https://guides.rubyonrails.org/security.html#content-security-policy
  Rails.application.config.content_security_policy do |policy|
    loader = ::Gitlab::ContentSecurityPolicy::ConfigLoader.new(csp_settings['directives'].to_h)
    loader.load(policy)
  end

  Rails.application.config.content_security_policy_report_only = csp_settings['report_only']
  Rails.application.config.content_security_policy_nonce_generator = ->(request) { SecureRandom.base64(16) }
  Rails.application.config.content_security_policy_nonce_directives = %w[script-src]
end
