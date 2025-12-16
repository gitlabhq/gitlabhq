# frozen_string_literal: true

module ProfilesHelper
  include UsersHelper

  def commit_email_select_options(user)
    private_email = user.private_commit_email
    verified_emails = user.verified_emails - [private_email]

    [
      [s_('Use primary email (%{email})') % { email: user.email }, ''],
      [
        safe_format(s_("Profiles|Use a private email - %{email}"), email: private_email),
        Gitlab::PrivateCommitEmail::TOKEN
      ],
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

  def ssh_key_usage_types
    {
      s_('SSHKey|Authentication & Signing') => 'auth_and_signing',
      s_('SSHKey|Authentication') => 'auth',
      s_('SSHKey|Signing') => 'signing'
    }
  end

  # Overridden in EE::ProfilesHelper#ssh_key_expiration_tooltip
  def ssh_key_expiration_tooltip(key)
    key.errors.full_messages.join(', ') if key.errors.full_messages.any?
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

  def email_resend_confirmation_link(user)
    return unless user.unconfirmed_email.present?

    Rails.application.routes.url_helpers.user_confirmation_path(user: { email: user.unconfirmed_email })
  end

  def user_profile_data(user)
    {
      profile_path: user_settings_profile_path,
      profile_avatar_path: profile_avatar_path,
      avatar_url: avatar_icon_for_user(user, current_user: current_user),
      has_avatar: user.avatar?.to_s,
      gravatar_enabled: gravatar_enabled?.to_s,
      gravatar_link: { hostname: Gitlab.config.gravatar.host, url: "https://#{Gitlab.config.gravatar.host}" }.to_json,

      brand_profile_image_guidelines: if current_appearance&.profile_image_guidelines?
                                        brand_profile_image_guidelines
                                      else
                                        ''
                                      end,

      cropper_css_path: ActionController::Base.helpers.stylesheet_path('lazy_bundles/cropper.css'),
      user_path: user_path(current_user),
      timezones: timezone_data_with_unique_identifiers.to_json,
      user_timezone: user.timezone,
      id: user.id,
      name: user.name,
      pronouns: user.pronouns,
      location: user.location,
      pronunciation: user.pronunciation,
      website_url: user.website_url,
      job_title: user.job_title,
      organization: user.user_detail_organization,
      bio: user.bio,
      include_private_contributions: user.include_private_contributions?.to_s,
      achievements_enabled: user.achievements_enabled.to_s,
      private_profile: user.private_profile?.to_s,
      **email_profile_data(user),
      **user_status_properties(user)
    }
  end

  def delete_account_modal_data
    {
      action_url: user_registration_path,
      confirm_with_password: current_user.confirm_deletion_with_password?.to_s,
      username: current_user.username,
      delay_user_account_self_deletion: Gitlab::CurrentSettings.delay_user_account_self_deletion.to_s
    }
  end

  def email_profile_data(user)
    {
      email: user.temp_oauth_email? ? '' : (user.email || ''),
      public_email: user.public_email,
      commit_email: user.commit_email,
      public_email_options: [
        { text: s_('Profiles|Do not show on profile'), value: '' },
        *user.public_verified_emails.map { |email| { text: email, value: email } }
      ].to_json,
      commit_email_options: commit_email_select_options(user).map do |option|
        if option.is_a?(Array)
          { text: option[0], value: option[1] }
        else
          { text: option, value: option }
        end
      end.to_json,
      email_help_text: sanitized_email_help_text(user),
      email_resend_confirmation_link: email_resend_confirmation_link(user),
      is_email_readonly: user.read_only_attribute?(:email),
      email_change_disabled: user.respond_to?(:managing_group) && user.managing_group.present?,
      managing_group_name: user.respond_to?(:managing_group) ? user.managing_group&.name : nil,
      needs_password_confirmation: needs_password_confirmation?(user).to_s,
      password_automatically_set: user.password_automatically_set?.to_s,
      allow_password_authentication_for_web: user.allow_password_authentication_for_web?.to_s,
      provider_label: attribute_provider_label(:email)
    }
  end

  def sanitized_email_help_text(user)
    help_text = user_email_help_text(user)
    return help_text unless help_text&.include?('<a')

    doc = Nokogiri::HTML::DocumentFragment.parse(help_text)

    doc.css('p').each do |p|
      should_remove = p.css('a[href*="user_confirmation"]').any? ||
        p.css('a[href*="confirmation"]').any? ||
        p.css('a').any? { |link| !link.text.strip.empty? && link['href']&.include?('confirmation') }

      p.remove if should_remove
    end

    sanitize(doc.to_html, tags: %w[strong p], attributes: [])
  end

  def email_otp_enrollment_restriction_readable_reason(user)
    return unless user && !user.can_modify_email_otp_enrollment?

    # rubocop:disable Layout/LineLength -- full length strings required for i18n
    case user.email_otp_enrollment_restriction
    when :feature_disabled
      s_('ProfilesAuthentication|You cannot modify your enrollment because the feature is disabled.')
    when :uses_external_authenticator
      s_('ProfilesAuthentication|You cannot modify your enrollment because your account does not use a password to sign in.')
    when :global_enforcement
      s_('ProfilesAuthentication|You cannot modify your enrollment because the instance requires OTP or WebAuthn two-factor authentication.')
    when :admin_2fa_enforcement
      s_('ProfilesAuthentication|You cannot modify your enrollment because administrators are required to use OTP or WebAuthn two-factor authentication.')
    when :group_enforcement
      s_('ProfilesAuthentication|You cannot modify your enrollment because a group you belong to requires OTP or WebAuthn two-factor authentication.')
    when :future_enforcement
      safe_format(s_("ProfilesAuthentication|You can skip email verification for now. Email verification becomes mandatory on %{date}."), date: l(user.email_otp_required_after.to_date, format: :long))
    when :email_otp_required
      s_('ProfilesAuthentication|You cannot modify your enrollment because email verification is required at a minimum.')
    else
      s_('ProfilesAuthentication|You cannot modify your enrollment because of an email OTP enrollment restriction.')
    end
    # rubocop:enable Layout/LineLength
  end

  def email_otp_enrollment_restriction_confirm_data(user)
    disabled = !user.can_modify_email_otp_enrollment?
    help_text = email_otp_enrollment_restriction_readable_reason(user) if disabled
    email_otp_required = user.email_otp_required_as_boolean

    {
      help_text: help_text,
      disabled: disabled.to_s,
      email_otp_required: email_otp_required.to_s,
      path: user_settings_profile_path
    }
  end

  private

  def needs_password_confirmation?(user)
    !user.password_automatically_set? && user.allow_password_authentication_for_web?
  end
end

ProfilesHelper.prepend_mod
