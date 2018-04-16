module SystemCheck
  module Geo
    class AuthorizedKeysCheck < ::SystemCheck::BaseCheck
      set_name 'OpenSSH configured to use AuthorizedKeysCommand'

      AUTHORIZED_KEYS_DOCS = 'doc/administration/operations/fast_ssh_key_lookup.md'.freeze
      OPENSSH_AUTHORIZED_KEYS_CMD_REGEXP = %r{
        ^AuthorizedKeysCommand # line starts with
        \s+                    # one space or more
        (?<quote>['"]?)        # detect optional quotes
        (?<content>[^#'"]+)    # content should be at least 1 char, non quotes or start-comment symbol
        \k<quote>              # boundary for command, backtracks the same detected quote, or none
        \s*                    # optional any amount of space character
        (?:\#.*)?$             # optional start-comment symbol followed by optionally any character until end of line
      }x
      OPENSSH_AUTHORIZED_KEYS_USER_REGEXP = %r{
        ^AuthorizedKeysCommandUser # line starts with
        \s+                        # one space or more
        (?<quote>['"]?)            # detect optional quotes
        (?<content>[^#'"]+)        # content should be at least 1 char, non quotes or start-comment symbol
        \k<quote>                  # boundary for command, backtracks the same detected quote, or none
        \s*                        # optional any amount of space character
        (?:\#.*)?$                 # optional start-comment symbol followed by optionally any character until end of line
      }x
      OPENSSH_EXPECTED_COMMAND = '/opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-shell-authorized-keys-check git %u %k'.freeze

      def multi_check
        unless openssh_config_exists?
          print_failure("Cannot find OpenSSH configuration file at: #{openssh_config_path}")

          if in_docker?
            try_fixing_it(
              'If you are not using our official docker containers,',
              'make sure you have OpenSSH server installed and configured correctly on this system'
            )

            for_more_information(AUTHORIZED_KEYS_DOCS)
          else
            try_fixing_it(
              'Make sure you have OpenSSH server installed on this system'
            )
          end

          return
        end

        unless openssh_config_readable?
          print_skipped('Cannot access OpenSSH configuration file')

          try_fixing_it(
            'This is expected if you are using SELinux. You may want to check configuration manually'
          )

          for_more_information(AUTHORIZED_KEYS_DOCS)
          return
        end

        authorized_keys_command = extract_authorized_keys_command
        unless authorized_keys_command
          print_failure('OpenSSH configuration file does not contain a AuthorizedKeysCommand')

          try_fixing_it(
            'Change your OpenSSH configuration file pointing to the correct command'
          )

          for_more_information(AUTHORIZED_KEYS_DOCS)
          return
        end

        unless openssh_is_expected_command?(authorized_keys_command)
          print_warning('OpenSSH configuration file points to a different AuthorizedKeysCommand')

          try_fixing_it(
            "We were expecting AuthorizedKeysCommand to be: #{OPENSSH_EXPECTED_COMMAND}",
            "but instead it is: #{authorized_keys_command}",
            'If you made a custom command, make sure it behaves according to GitLab\'s Documentation'
          )

          for_more_information(AUTHORIZED_KEYS_DOCS)
          # this check should not block the others
        end

        authorized_keys_command_path = openssh_extract_command_path(authorized_keys_command)
        unless File.file?(authorized_keys_command_path)
          print_failure("Cannot find configured AuthorizedKeysCommand: #{authorized_keys_command_path}")

          try_fixing_it(
            'You need to create the file and add the correct content to it'
          )

          for_more_information(AUTHORIZED_KEYS_DOCS)
          return
        end

        authorized_keys_command_user = extract_authorized_keys_command_user
        unless authorized_keys_command_user
          print_failure('OpenSSH configuration file does not contain a AuthorizedKeysCommandUser')

          try_fixing_it(
            'Change your OpenSSH configuration file pointing to the correct user'
          )

          for_more_information(AUTHORIZED_KEYS_DOCS)
          return
        end

        unless authorized_keys_command_user == gitlab_user
          print_warning('OpenSSH configuration file points to a different AuthorizedKeysCommandUser')

          try_fixing_it(
            "We were expecting AuthorizedKeysCommandUser to be: #{gitlab_user}",
            "but instead it is: #{authorized_keys_command_user}",
            'Fix your OpenSSH configuration file pointing to the correct user'
          )

          for_more_information(AUTHORIZED_KEYS_DOCS)
          return
        end

        $stdout.puts 'yes'.color(:green)
        true
      end

      def extract_authorized_keys_command
        extract_openssh_config(OPENSSH_AUTHORIZED_KEYS_CMD_REGEXP)
      end

      def extract_authorized_keys_command_user
        extract_openssh_config(OPENSSH_AUTHORIZED_KEYS_USER_REGEXP)
      end

      def openssh_config_path
        @openssh_config_path ||= begin
          if in_docker?
            '/assets/sshd_config' # path in our official docker containers
          else
            '/etc/ssh/sshd_config'
          end
        end
      end

      private

      def print_skipped(reason)
        $stdout.puts 'skipped'.color(:magenta)

        $stdout.puts '  Reason:'.color(:blue)
        $stdout.puts "  #{reason}"
      end

      def print_warning(reason)
        $stdout.puts 'warning'.color(:magenta)

        $stdout.puts '  Reason:'.color(:blue)
        $stdout.puts "  #{reason}"
      end

      def print_failure(reason)
        $stdout.puts 'no'.color(:red)

        $stdout.puts '  Reason:'.color(:blue)
        $stdout.puts "  #{reason}"
      end

      def openssh_config_exists?
        File.file?(openssh_config_path)
      end

      def openssh_config_readable?
        File.readable?(openssh_config_path)
      end

      def openssh_extract_command_path(cmd_with_params)
        cmd_with_params.split(' ').first
      end

      def openssh_is_expected_command?(authorized_keys_command)
        authorized_keys_command.squeeze(' ') == OPENSSH_EXPECTED_COMMAND
      end

      def in_docker?
        File.file?('/.dockerenv')
      end

      def gitlab_user
        Gitlab.config.gitlab.user
      end

      def extract_openssh_config(regexp)
        return false unless openssh_config_exists? && openssh_config_readable?

        File.open(openssh_config_path) do |f|
          f.each_line do |line|
            if (match = line.match(regexp))
              raw_content = match[:content]
              # remove linebreak, and lead and trailing spaces
              return raw_content.chomp.strip # rubocop:disable Cop/AvoidReturnFromBlocks
            end
          end
        end

        nil
      end
    end
  end
end
