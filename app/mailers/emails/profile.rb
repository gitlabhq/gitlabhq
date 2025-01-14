# frozen_string_literal: true

module Emails
  module Profile
    include SafeFormatHelper

    def new_user_email(user_id, token = nil)
      @current_user = @user = User.find(user_id)
      @target_url = user_url(@user)
      @token = token
      email_with_layout(to: @user.notification_email_or_default, subject: subject("Account was created for you"))
    end

    def instance_access_request_email(user, recipient)
      @user = user
      @recipient = recipient

      email_with_layout(
        to: recipient.notification_email_or_default,
        subject: subject(_("GitLab Account Request")))
    end

    def user_admin_rejection_email(name, email)
      @name = name

      email_with_layout(
        to: email,
        subject: subject(_("GitLab account request rejected")))
    end

    def user_deactivated_email(name, email)
      @name = name
      @host = Gitlab.config.gitlab.host

      email_with_layout(
        to: email,
        subject: subject(_('Your account has been deactivated')))
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def new_ssh_key_email(key_id)
      @key = Key.find_by(id: key_id)

      return unless @key

      @current_user = @user = @key.user
      @target_url = user_url(@user)
      email_with_layout(to: @user.notification_email_or_default, subject: subject("SSH key was added to your account"))
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def new_gpg_key_email(gpg_key_id)
      @gpg_key = GpgKey.find_by(id: gpg_key_id)

      return unless @gpg_key

      @current_user = @user = @gpg_key.user
      @target_url = user_url(@user)
      mail_with_locale(to: @user.notification_email_or_default, subject: subject("GPG key was added to your account"))
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # resource owners are sent mail about expiring access tokens which belong to a bot user
    def bot_resource_access_token_about_to_expire_email(recipient, resource, token_name, params = {})
      params = params.with_indifferent_access
      @user = recipient
      @token_name = token_name
      @days_to_expire = params.fetch(:days_to_expire, PersonalAccessToken::DAYS_TO_EXPIRE)
      @resource = resource
      if resource.is_a?(Group)
        @target_url = group_settings_access_tokens_url(resource)
        @reason_text = _('You are receiving this email because you are an Owner of the Group.')
      else
        @target_url = project_settings_access_tokens_url(resource)
        @reason_text = _('You are receiving this email because you are either an Owner or Maintainer of the project.')
      end

      email_with_layout(
        to: recipient.notification_email_or_default,
        subject: subject(
          safe_format(
            _("Your resource access tokens will expire in %{days_to_expire} or less"),
            days_to_expire: pluralize(@days_to_expire, _('day'))
          )
        )
      )
    end

    def access_token_created_email(user, token_name)
      return unless user&.active?

      @user = user
      @target_url = user_settings_personal_access_tokens_url
      @token_name = token_name

      email_with_layout(
        to: @user.notification_email_or_default,
        subject: subject(_("A new personal access token has been created"))
      )
    end

    def access_token_about_to_expire_email(user, token_names, params = {})
      return unless user

      params = params.with_indifferent_access

      @user = user
      @token_names = token_names
      @target_url = user_settings_personal_access_tokens_url
      @days_to_expire = params.fetch(:days_to_expire, PersonalAccessToken::DAYS_TO_EXPIRE)

      email_with_layout(
        to: @user.notification_email_or_default,
        subject: subject(
          _("Your personal access tokens will expire in %{days_to_expire} days or less") % {
            days_to_expire: @days_to_expire
          }
        )
      )
    end

    def access_token_expired_email(user, token_names = [])
      return unless user && user.active?

      @user = user
      @token_names = token_names
      @target_url = user_settings_personal_access_tokens_url

      email_with_layout(
        to: @user.notification_email_or_default,
        subject: subject(_("Your personal access tokens have expired"))
      )
    end

    def access_token_revoked_email(user, token_name, source = nil)
      return unless user&.active?

      @user = user
      @token_name = token_name
      @target_url = user_settings_personal_access_tokens_url
      @source = source

      email_with_layout(
        to: @user.notification_email_or_default,
        subject: subject(_("Your personal access token has been revoked"))
      )
    end

    def ssh_key_expired_email(user, fingerprints)
      return unless user&.active?

      @user = user
      @fingerprints = fingerprints
      @target_url = user_settings_ssh_keys_url

      email_with_layout(to: @user.notification_email_or_default, subject: subject(_("Your SSH key has expired")))
    end

    def ssh_key_expiring_soon_email(user, fingerprints)
      return unless user&.active?

      @user = user
      @fingerprints = fingerprints
      @target_url = user_settings_ssh_keys_url

      mail_with_locale(to: @user.notification_email_or_default, subject: subject(_("Your SSH key is expiring soon.")))
    end

    def unknown_sign_in_email(user, ip, time, request_info = {})
      @user = user
      @ip = ip
      @city = request_info[:city]
      @country = request_info[:country]
      @time = time
      @target_url = edit_user_settings_password_url

      email_with_layout(
        to: @user.notification_email_or_default,
        subject: subject(_("%{host} sign-in from new location") % { host: Gitlab.config.gitlab.host }))
    end

    def two_factor_otp_attempt_failed_email(user, ip, time = Time.current)
      @user = user
      @ip = ip
      @time = time

      email_with_layout(
        to: @user.notification_email_or_default,
        subject: subject(
          _("Attempted sign in to %{host} using an incorrect verification code") % {
            host: Gitlab.config.gitlab.host
          }
        )
      )
    end

    def disabled_two_factor_email(user)
      return unless user

      @user = user

      email_with_layout(
        to: @user.notification_email_or_default,
        subject: subject(_("Two-factor authentication disabled"))
      )
    end

    def new_email_address_added_email(user, email)
      return unless user

      @user = user
      @email = email

      email_with_layout(to: @user.notification_email_or_default, subject: subject(_("New email address added")))
    end

    def new_achievement_email(user, achievement)
      return unless user&.active?

      @user = user
      @achievement = achievement

      email_with_layout(
        to: @user.notification_email_or_default,
        subject: subject(
          s_("Achievements|%{namespace_full_path} awarded you the %{achievement_name} achievement") % {
            namespace_full_path: @achievement.namespace.full_path, achievement_name: @achievement.name
          }
        )
      )
    end
  end
end

Emails::Profile.prepend_mod_with('Emails::Profile')
