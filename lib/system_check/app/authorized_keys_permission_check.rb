# frozen_string_literal: true

module SystemCheck
  module App
    class AuthorizedKeysPermissionCheck < SystemCheck::BaseCheck
      set_name 'Is authorized keys file accessible?'
      set_skip_reason 'skipped (authorized keys not enabled)'

      def skip?
        !authorized_keys_enabled?
      end

      def check?
        authorized_keys.accessible?
      end

      def repair!
        authorized_keys.create
      end

      def show_error
        try_fixing_it(
          [
            "sudo chmod 700 #{File.dirname(authorized_keys.file)}",
            "touch #{authorized_keys.file}",
            "sudo chmod 600 #{authorized_keys.file}"
          ])
        fix_and_rerun
      end

      private

      def authorized_keys_enabled?
        Gitlab::CurrentSettings.current_application_settings.authorized_keys_enabled
      end

      def authorized_keys
        @authorized_keys ||= Gitlab::AuthorizedKeys.new
      end
    end
  end
end
