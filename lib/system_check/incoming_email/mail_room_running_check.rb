# frozen_string_literal: true

module SystemCheck
  module IncomingEmail
    class MailRoomRunningCheck < SystemCheck::BaseCheck
      include ::SystemCheck::InitHelpers

      set_name 'MailRoom running?'

      def skip?
        return true if omnibus_gitlab?

        unless mail_room_enabled? || mail_room_configured?
          self.skip_reason = "can't check because of previous errors"
          true
        end
      end

      def check?
        mail_room_running?
      end

      def show_error
        try_fixing_it(
          'Start mail_room'
        )
        for_more_information(
          'doc/administration/incoming_email.md',
          'see log/mail_room.log for possible errors'
        )
        fix_and_rerun
      end

      private

      def mail_room_enabled?
        target = '/usr/local/lib/systemd/system/gitlab.target'
        service = '/usr/local/lib/systemd/system/gitlab-mailroom.service'

        File.exist?(target) && File.exist?(service) && systemd_get_wants('gitlab.target').include?("gitlab-mailroom.service")
      end

      def mail_room_configured?
        path = '/etc/default/gitlab'
        File.exist?(path) && File.read(path).include?('mail_room_enabled=true')
      end

      def mail_room_running?
        ps_ux, _ = Gitlab::Popen.popen(%w[ps uxww])
        ps_ux.include?("mail_room")
      end
    end
  end
end
