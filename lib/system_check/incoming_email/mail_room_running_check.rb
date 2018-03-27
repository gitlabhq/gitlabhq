module SystemCheck
  module IncomingEmail
    class MailRoomRunningCheck < SystemCheck::BaseCheck
      set_name 'MailRoom running?'

      def skip?
        return true if omnibus_gitlab?

        unless mail_room_configured?
          self.skip_reason = "can't check because of previous errors"
          true
        end
      end

      def check?
        mail_room_running?
      end

      def show_error
        try_fixing_it(
          sudo_gitlab('RAILS_ENV=production bin/mail_room start')
        )
        for_more_information(
          see_installation_guide_section('Install Init Script'),
          'see log/mail_room.log for possible errors'
        )
        fix_and_rerun
      end

      private

      def mail_room_configured?
        path = '/etc/default/gitlab'
        File.exist?(path) && File.read(path).include?('mail_room_enabled=true')
      end

      def mail_room_running?
        ps_ux, _ = Gitlab::Popen.popen(%w(ps uxww))
        ps_ux.include?("mail_room")
      end
    end
  end
end
