# frozen_string_literal: true

module LicenseHelper
  def self_managed_new_trial_url
    subscription_portal_new_trial_url(return_to: CGI.escape(Gitlab.config.gitlab.url))
  end
end

LicenseHelper.prepend_mod_with('LicenseHelper')
