# frozen_string_literal: true

module Emails
  module IdentityVerification
    include Gitlab::Email::SingleRecipientValidator

    def verification_instructions_email(email, token:)
      validate_single_recipient_in_email!(email)

      @token = token
      @expires_in_minutes = Users::EmailVerification::ValidateTokenService::TOKEN_VALID_FOR_MINUTES
      @password_link = edit_user_settings_password_url
      @two_fa_link = help_page_url('user/profile/account/two_factor_authentication.md')

      headers = {
        to: email,
        subject: s_('IdentityVerification|Verify your identity'),
        'X-Mailgun-Suppressions-Bypass' => 'true'
      }

      mail_with_locale(headers) do |format|
        format.html { render layout: 'mailer' }
        format.text
      end
    end

    def verification_instructions_sent_to_secondary_email(primary_email, secondary_email)
      validate_single_recipient_in_email!(primary_email)

      @password_link = help_page_url('user/profile/user_passwords.md', anchor: 'change-your-password')
      @two_fa_link = help_page_url('user/profile/account/two_factor_authentication_troubleshooting.md')
      @account_settings_link = profile_account_url
      @user_secondary_email = secondary_email

      headers = {
        to: primary_email,
        subject: s_('IdentityVerification|Verification code sent to your secondary email address'),
        'X-Mailgun-Suppressions-Bypass' => 'true'
      }

      mail_with_locale(headers) do |format|
        format.html { render layout: 'mailer' }
        format.text
      end
    end
  end
end

Emails::IdentityVerification.prepend_mod
