# frozen_string_literal: true

module ProfilesHelper
  def commit_email_select_options(user)
    private_email = user.private_commit_email
    verified_emails = user.verified_emails - [private_email]

    [
      [s_('Use primary email (%{email})') % { email: user.email }, ''],
      [s_("Profiles|Use a private email - %{email}").html_safe % { email: private_email }, Gitlab::PrivateCommitEmail::TOKEN],
      *verified_emails
    ]
  end

  def attribute_provider_label(attribute)
    user_synced_attributes_metadata = current_user.user_synced_attributes_metadata
    if user_synced_attributes_metadata&.synced?(attribute)
      if user_synced_attributes_metadata.provider
        Gitlab::Auth::OAuth::Provider.label_for(user_synced_attributes_metadata.provider)
      else
        'LDAP'
      end
    end
  end

  def user_profile?
    params[:controller] == 'users'
  end

  def middle_dot_divider_classes(stacking, breakpoint)
    ['gl-mb-3'].tap do |classes|
      if stacking
        classes.concat(%w[middle-dot-divider-sm gl-display-block gl-sm-display-inline-block])
      else
        classes << 'gl-display-inline-block'
        classes << if breakpoint.nil?
                     'middle-dot-divider'
                   else
                     "middle-dot-divider-#{breakpoint}"
                   end
      end
    end
  end

  def ssh_key_usage_types
    {
      s_('SSHKey|Authentication & Signing') => 'auth_and_signing',
      s_('SSHKey|Authentication') => 'auth',
      s_('SSHKey|Signing') => 'signing'
    }
  end

  # Overridden in EE::ProfilesHelper#ssh_key_expiration_tooltip
  def ssh_key_expiration_tooltip(key)
    return key.errors.full_messages.join(', ') if key.errors.full_messages.any?
  end

  # Overridden in EE::ProfilesHelper#ssh_key_expires_field_description
  def ssh_key_expires_field_description
    s_('Profiles|Optional but recommended. If set, key becomes invalid on the specified date.')
  end

  # Overridden in EE::ProfilesHelper#ssh_key_expiration_policy_enabled?
  def ssh_key_expiration_policy_enabled?
    false
  end

  # Overridden in EE::ProfilesHelper#prevent_delete_account?
  def prevent_delete_account?
    false
  end

  def user_profile_data(user)
    {
      profile_path: user_settings_profile_path,
      profile_avatar_path: profile_avatar_path,
      avatar_url: avatar_icon_for_user(user, current_user: current_user),
      has_avatar: user.avatar?.to_s,
      gravatar_enabled: gravatar_enabled?.to_s,
      gravatar_link: { hostname: Gitlab.config.gravatar.host, url: "https://#{Gitlab.config.gravatar.host}" }.to_json,
      brand_profile_image_guidelines: current_appearance&.profile_image_guidelines? ? brand_profile_image_guidelines : '',
      cropper_css_path: ActionController::Base.helpers.stylesheet_path('lazy_bundles/cropper.css'),
      user_path: user_path(current_user),
      timezones: timezone_data_with_unique_identifiers.to_json,
      user_timezone: user.timezone,
      **user_status_properties(user)
    }
  end
end

ProfilesHelper.prepend_mod
