# frozen_string_literal: true

module LicenseHelper
  def self_managed_new_trial_url
    subscription_portal_new_trial_url(
      return_to: general_admin_application_settings_url(anchor: 'js-add-license-toggle')
    )
  end
end

LicenseHelper.prepend_mod_with('LicenseHelper')
