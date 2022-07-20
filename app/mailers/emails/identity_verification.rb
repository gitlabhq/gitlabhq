# frozen_string_literal: true

module Emails
  module IdentityVerification
    def verification_instructions_email(user_id, token:, expires_in:)
      @token = token
      @expires_in_minutes = expires_in
      @password_link = edit_profile_password_url
      @two_fa_link = help_page_url('user/profile/account/two_factor_authentication')

      user = User.find(user_id)
      email_with_layout(to: user.email, subject: s_('IdentityVerification|Verify your identity'))
    end
  end
end
