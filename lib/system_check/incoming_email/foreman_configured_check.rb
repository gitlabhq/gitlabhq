module SystemCheck
  module IncomingEmail
    class ForemanConfiguredCheck < SystemCheck::BaseCheck
      set_name 'Foreman configured correctly?'

      def check?
        path = Rails.root.join('Procfile')

        File.exist?(path) && File.read(path) =~ /^mail_room:/
      end

      def show_error
        try_fixing_it(
          'Enable mail_room in your Procfile.'
        )
        for_more_information(
          'doc/administration/reply_by_email.md'
        )
        fix_and_rerun
      end
    end
  end
end
