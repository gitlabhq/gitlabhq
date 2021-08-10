# frozen_string_literal: true
module RestrictedSignup
  extend ActiveSupport::Concern

  private

  def validate_admin_signup_restrictions(email)
    return if allowed_domain?(email)

    if allowlist_present?
      return _('domain is not authorized for sign-up.')
    elsif denied_domain?(email)
      return _('is not from an allowed domain.')
    elsif restricted_email?(email)
      return _('is not allowed. Try again with a different email address, or contact your GitLab admin.')
    end

    nil
  end

  def denied_domain?(email)
    return false unless Gitlab::CurrentSettings.domain_denylist_enabled?

    denied_domains = Gitlab::CurrentSettings.domain_denylist
    denied_domains.present? && domain_matches?(denied_domains, email)
  end

  def allowlist_present?
    Gitlab::CurrentSettings.domain_allowlist.present?
  end

  def allowed_domain?(email)
    allowed_domains = Gitlab::CurrentSettings.domain_allowlist
    allowlist_present? && domain_matches?(allowed_domains, email)
  end

  def restricted_email?(email)
    return false unless Gitlab::CurrentSettings.email_restrictions_enabled?

    restrictions = Gitlab::CurrentSettings.email_restrictions
    restrictions.present? && Gitlab::UntrustedRegexp.new(restrictions).match?(email)
  end

  def domain_matches?(email_domains, email)
    signup_domain = Mail::Address.new(email).domain
    email_domains.any? do |domain|
      escaped = Regexp.escape(domain).gsub('\*', '.*?')
      regexp = Regexp.new "^#{escaped}$", Regexp::IGNORECASE
      signup_domain =~ regexp
    end
  end
end
