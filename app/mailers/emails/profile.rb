# frozen_string_literal: true

module Emails
  module Profile
    def new_user_email(user_id, token = nil)
      @current_user = @user = User.find(user_id)
      @target_url = user_url(@user)
      @token = token
      mail(to: @user.notification_email, subject: subject("Account was created for you"))
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

    def access_token_about_to_expire_email(user)
      return unless user

      @user = user
      @target_url = profile_personal_access_tokens_url
      @days_to_expire = PersonalAccessToken::DAYS_TO_EXPIRE

      Gitlab::I18n.with_locale(@user.preferred_language) do
        mail(to: @user.notification_email, subject: subject(_("Your Personal Access Tokens will expire in %{days_to_expire} days or less") % { days_to_expire: @days_to_expire }))
      end
    end
  end
end

Emails::Profile.prepend_if_ee('EE::Emails::Profile')
