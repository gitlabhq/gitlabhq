# frozen_string_literal: true

module RestrictedSignup
  extend ActiveSupport::Concern

  private

  def validate_admin_signup_restrictions(email)
    return if allowed_domain?(email)

    error_type = fetch_error_type(email)

    return unless error_type.present?

    [
      signup_email_invalid_message,
      error_message[created_by_key][error_type]
    ].join(' ')
  end

  def fetch_error_type(email)
    if allowlist_present?
      :allowlist
    elsif denied_domain?(email)
      :denylist
    elsif restricted_email?(email)
      :restricted
    end
  end

  def error_message
    {
      admin: {
        allowlist: ERB::Util.html_escape_once(_("Go to the 'Admin area &gt; Sign-up restrictions', and check 'Allowed domains for sign-ups'.")).html_safe,
        denylist: ERB::Util.html_escape_once(_("Go to the 'Admin area &gt; Sign-up restrictions', and check the 'Domain denylist'.")).html_safe,
        restricted: ERB::Util.html_escape_once(_("Go to the 'Admin area &gt; Sign-up restrictions', and check 'Email restrictions for sign-ups'.")).html_safe,
        group_setting: ERB::Util.html_escape_once(_("Go to the group’s 'Settings &gt; General' page, and check 'Restrict membership by email domain'.")).html_safe
      },
      nonadmin: {
        allowlist: error_nonadmin,
        denylist: error_nonadmin,
        restricted: error_nonadmin,
        group_setting: error_nonadmin
      }
    }
  end

  def error_nonadmin
    _("Check with your administrator.")
  end

  def created_by_key
    created_by&.can_admin_all_resources? ? :admin : :nonadmin
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

::RestrictedSignup.prepend_mod
