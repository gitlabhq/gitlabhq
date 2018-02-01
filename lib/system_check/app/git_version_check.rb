module SystemCheck
  module App
    class GitVersionCheck < SystemCheck::BaseCheck
      set_name -> { "Git version >= #{self.required_version} ?" }
      set_check_pass -> { "yes (#{self.current_version})" }

      def self.required_version
        @required_version ||= Gitlab::VersionInfo.new(2, 9, 5)
      end

      def self.current_version
        @current_version ||= Gitlab::VersionInfo.parse(Gitlab::TaskHelpers.run_command(%W(#{Gitlab.config.git.bin_path} --version)))
      end

      def check?
        self.class.current_version.valid? && self.class.required_version <= self.class.current_version
      end

      def show_error
        $stdout.puts "Your git bin path is \"#{Gitlab.config.git.bin_path}\""

        try_fixing_it(
          "Update your git to a version >= #{self.class.required_version} from #{self.class.current_version}"
        )
        fix_and_rerun
      end
    end
  end
end
