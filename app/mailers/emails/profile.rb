# frozen_string_literal: true

module Emails
  module Profile
    def new_user_email(user_id, token = nil)
      @current_user = @user = User.find(user_id)
      @target_url = user_url(@user)
      @token = token
      mail(to: @user.notification_email, subject: subject("Account was created for you"))
    end

    def instance_access_request_email(user, recipient)
      @user = user
      @recipient = recipient

      profile_email_with_layout(
        to: recipient.notification_email,
        subject: subject(_("GitLab Account Request")))
    end

    def user_admin_rejection_email(name, email)
      @name = name

      profile_email_with_layout(
        to: email,
        subject: subject(_("GitLab account request rejected")))
    end

    def user_deactivated_email(name, email)
      @name = name

      profile_email_with_layout(
        to: email,
        subject: subject(_('Your account has been deactivated')))
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def new_ssh_key_email(key_id)
      @key = Key.find_by(id: key_id)

      return unless @key

      @current_user = @user = @key.user
      @target_url = user_url(@user)
      mail(to: @user.notification_email, subject: subject("SSH key was added to your account"))
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def new_gpg_key_email(gpg_key_id)
      @gpg_key = GpgKey.find_by(id: gpg_key_id)

      return unless @gpg_key

      @current_user = @user = @gpg_key.user
      @target_url = user_url(@user)
      mail(to: @user.notification_email, subject: subject("GPG key was added to your account"))
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def access_token_about_to_expire_email(user, token_names)
      return unless user

      @user = user
      @token_names = token_names
      @target_url = profile_personal_access_tokens_url
      @days_to_expire = PersonalAccessToken::DAYS_TO_EXPIRE

      Gitlab::I18n.with_locale(@user.preferred_language) do
        mail(to: @user.notification_email, subject: subject(_("Your personal access tokens will expire in %{days_to_expire} days or less") % { days_to_expire: @days_to_expire }))
      end
    end

    def access_token_expired_email(user)
      return unless user && user.active?

      @user = user
      @target_url = profile_personal_access_tokens_url

      Gitlab::I18n.with_locale(@user.preferred_language) do
        mail(to: @user.notification_email, subject: subject(_("Your personal access token has expired")))
      end
    end

    def ssh_key_expired_email(user, fingerprints)
      return unless user&.active?

      @user = user
      @fingerprints = fingerprints
      @target_url = profile_keys_url

      Gitlab::I18n.with_locale(@user.preferred_language) do
        mail(to: @user.notification_email, subject: subject(_("Your SSH key has expired")))
      end
    end

    def ssh_key_expiring_soon_email(user, fingerprints)
      return unless user&.active?

      @user = user
      @fingerprints = fingerprints
      @target_url = profile_keys_url

      Gitlab::I18n.with_locale(@user.preferred_language) do
        mail(to: @user.notification_email, subject: subject(_("Your SSH key is expiring soon.")))
      end
    end

    def unknown_sign_in_email(user, ip, time)
      @user = user
      @ip = ip
      @time = time
      @target_url = edit_profile_password_url

      Gitlab::I18n.with_locale(@user.preferred_language) do
        profile_email_with_layout(
          to: @user.notification_email,
          subject: subject(_("%{host} sign-in from new location") % { host: Gitlab.config.gitlab.host }))
      end
    end

    def disabled_two_factor_email(user)
      return unless user

      @user = user

      Gitlab::I18n.with_locale(@user.preferred_language) do
        mail(to: @user.notification_email, subject: subject(_("Two-factor authentication disabled")))
      end
    end

    private

    def profile_email_with_layout(to:, subject:, layout: 'mailer')
      mail(to: to, subject: subject) do |format|
        format.html { render layout: layout }
        format.text { render layout: layout }
      end
    end
  end
end

Emails::Profile.prepend_mod_with('Emails::Profile')
