# frozen_string_literal: true

module AccountsHelper
  def incoming_email_token_enabled?
    current_user.incoming_email_token && Gitlab::Email::IncomingEmail.supports_issue_creation?
  end
end
