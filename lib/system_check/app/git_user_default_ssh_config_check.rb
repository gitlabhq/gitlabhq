# frozen_string_literal: true

module SystemCheck
  module App
    class GitUserDefaultSSHConfigCheck < SystemCheck::BaseCheck
      # These files are allowed in the .ssh directory. The `config` file is not
      # whitelisted as it may change the SSH client's behaviour dramatically.
      WHITELIST = %w[
        authorized_keys
        authorized_keys.lock
        authorized_keys2
        known_hosts
      ].freeze

      set_name 'Git user has default SSH configuration?'
      set_skip_reason 'skipped (git user is not present / configured)'

      def skip?
        !home_dir || !File.directory?(home_dir)
      end

      def check?
        forbidden_files.empty?
      end

      def show_error
        backup_dir = "~/gitlab-check-backup-#{Time.now.to_i}"

        instructions = forbidden_files.map do |filename|
          "sudo mv #{Shellwords.escape(filename)} #{backup_dir}"
        end

        try_fixing_it("mkdir #{backup_dir}", *instructions)
        for_more_information('doc/ssh/index.md in section "Overriding SSH settings on the GitLab server"')
        fix_and_rerun
      end

      private

      def git_user
        Gitlab.config.gitlab.user
      end

      def home_dir
        return @home_dir if defined?(@home_dir)

        @home_dir =
          begin
            File.expand_path("~#{git_user}")
          rescue ArgumentError
            nil
          end
      end

      def ssh_dir
        return unless home_dir

        File.join(home_dir, '.ssh')
      end

      def forbidden_files
        @forbidden_files ||=
          begin
            present = Dir[File.join(ssh_dir, '*')]
            whitelisted = WHITELIST.map { |basename| File.join(ssh_dir, basename) }

            present - whitelisted
          end
      end
    end
  end
end
