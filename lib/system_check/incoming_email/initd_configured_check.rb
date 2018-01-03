module SystemCheck
  module IncomingEmail
    class InitdConfiguredCheck < SystemCheck::BaseCheck
      set_name 'Init.d configured correctly?'

      def skip?
        omnibus_gitlab?
      end

      def check?
        mail_room_configured?
      end

      def show_error
        try_fixing_it(
          'Enable mail_room in the init.d configuration.'
        )
        for_more_information(
          'doc/administration/reply_by_email.md'
        )
        fix_and_rerun
      end

      private

      def mail_room_configured?
        path = '/etc/default/gitlab'
        File.exist?(path) && File.read(path).include?('mail_room_enabled=true')
      end
    end
  end
end
