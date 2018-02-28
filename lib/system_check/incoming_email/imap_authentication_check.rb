module SystemCheck
  module IncomingEmail
    class ImapAuthenticationCheck < SystemCheck::BaseCheck
      set_name 'IMAP server credentials are correct?'

      def check?
        if mailbox_config
          begin
            imap = Net::IMAP.new(config[:host], port: config[:port], ssl: config[:ssl])
            imap.starttls if config[:start_tls]
            imap.login(config[:email], config[:password])
            connected = true
          rescue
            connected = false
          end
        end

        connected
      end

      def show_error
        try_fixing_it(
          'Check that the information in config/gitlab.yml is correct'
        )
        for_more_information(
          'doc/administration/reply_by_email.md'
        )
        fix_and_rerun
      end

      private

      def mailbox_config
        return @config if @config

        config_path = Rails.root.join('config', 'mail_room.yml').to_s
        erb = ERB.new(File.read(config_path))
        erb.filename = config_path
        config_file = YAML.load(erb.result)

        @config = config_file[:mailboxes]&.first
      end
    end
  end
end
