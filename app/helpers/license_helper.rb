# frozen_string_literal: true

module LicenseHelper
  def self_managed_new_trial_url
    return unless current_user

    subscription_portal_new_trial_url(
      return_to: CGI.escape(Gitlab.config.gitlab.url),
      id: Base64.strict_encode64(current_user.email)
    )
  end
end

LicenseHelper.prepend_mod_with('LicenseHelper')
