# frozen_string_literal: true

module SystemCheck
  # Used by gitlab:incoming_email:check rake task
  class IncomingEmailCheck < BaseCheck
    set_name 'Incoming Email:'

    def multi_check
      if Gitlab.config.incoming_email.enabled
        checks = []

        if Gitlab.config.incoming_email.inbox_method == 'imap'
          checks << SystemCheck::IncomingEmail::ImapAuthenticationCheck
        end

        if Rails.env.production?
          checks << SystemCheck::IncomingEmail::MailRoomEnabledCheck
          checks << SystemCheck::IncomingEmail::MailRoomRunningCheck
        end

        SystemCheck.run('Reply by email', checks)
      else
        $stdout.puts 'Reply by email is disabled in config/gitlab.yml'
      end
    end
  end
end
