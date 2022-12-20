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

  def availability_values
    Types::AvailabilityEnum.enum
  end

  def middle_dot_divider_classes(stacking, breakpoint)
    ['gl-mb-3'].tap do |classes|
      if stacking
        classes.concat(%w(middle-dot-divider-sm gl-display-block gl-sm-display-inline-block))
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
end

ProfilesHelper.prepend_mod
