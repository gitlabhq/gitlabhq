# frozen_string_literal: true

module SystemCheck
  module IncomingEmail
    class ImapAuthenticationCheck < SystemCheck::BaseCheck
      set_name 'IMAP server credentials are correct?'

      def check?
        if config
          try_connect_imap
        else
          @error = "#{mail_room_config_path} does not have mailboxes set up"
          false
        end
      end

      def show_error
        try_fixing_it(
          "An error occurred: #{@error.class}: #{@error.message}",
          'Check that the information in config/gitlab.yml is correct'
        )
        for_more_information(
          'doc/administration/reply_by_email.md'
        )
        fix_and_rerun
      end

      private

      def try_connect_imap
        config.each do |mailbox|
          $stdout.puts "Checking #{mailbox[:email]}"
          imap = Net::IMAP.new(mailbox[:host], port: mailbox[:port], ssl: mailbox[:ssl])
          imap.starttls if mailbox[:start_tls]
          imap.login(mailbox[:email], mailbox[:password])
        end
        true
      rescue StandardError => error
        @error = error
        false
      end

      def config
        @config ||= load_config
      end

      def mail_room_config_path
        @mail_room_config_path ||=
          Rails.root.join('config', 'mail_room.yml').to_s
      end

      def load_config
        erb = ERB.new(File.read(mail_room_config_path))
        erb.filename = mail_room_config_path
        config_file = YAML.safe_load(erb.result, permitted_classes: [Symbol])

        config_file[:mailboxes]
      end
    end
  end
end
