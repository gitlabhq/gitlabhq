module SystemCheck
  module App
    class GitConfigCheck < SystemCheck::BaseCheck
      OPTIONS = {
        'core.autocrlf' => 'input'
      }.freeze

      set_name 'Git configured correctly?'

      def check?
        correct_options = OPTIONS.map do |name, value|
          run_command(%W(#{Gitlab.config.git.bin_path} config --global --get #{name})).try(:squish) == value
        end

        correct_options.all?
      end

      # Tries to configure git itself
      #
      # Returns true if all subcommands were successful (according to their exit code)
      # Returns false if any or all subcommands failed.
      def repair!
        return false unless gitlab_user?

        command_success = OPTIONS.map do |name, value|
          system(*%W(#{Gitlab.config.git.bin_path} config --global #{name} #{value}))
        end

        command_success.all?
      end

      def show_error
        try_fixing_it(
          sudo_gitlab("\"#{Gitlab.config.git.bin_path}\" config --global core.autocrlf \"#{OPTIONS['core.autocrlf']}\"")
        )
        for_more_information(
          see_installation_guide_section 'GitLab'
        )
      end
    end
  end
end
