# frozen_string_literal: true

module SystemCheck
  # Used by gitlab:incoming_email:check rake task
  class IncomingEmailCheck < BaseCheck
    set_name 'Incoming Email:'

    def multi_check
      if Gitlab.config.incoming_email.enabled
        checks = [
          SystemCheck::IncomingEmail::ImapAuthenticationCheck
        ]

        if Rails.env.production?
          checks << SystemCheck::IncomingEmail::InitdConfiguredCheck
          checks << SystemCheck::IncomingEmail::MailRoomRunningCheck
        end

        SystemCheck.run('Reply by email', checks)
      else
        $stdout.puts 'Reply by email is disabled in config/gitlab.yml'
      end
    end
  end
end
