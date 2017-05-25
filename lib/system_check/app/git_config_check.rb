module SystemCheck
  module App
    class GitConfigCheck < SystemCheck::BaseCheck
      OPTIONS = {
        'core.autocrlf' => 'input'
      }.freeze

      set_name 'Git configured with autocrlf=input?'

      def check?
        correct_options = OPTIONS.map do |name, value|
          run_command(%W(#{Gitlab.config.git.bin_path} config --global --get #{name})).try(:squish) == value
        end

        correct_options.all?
      end

      def repair!
        auto_fix_git_config(OPTIONS)
      end

      def show_error
        try_fixing_it(
          sudo_gitlab("\"#{Gitlab.config.git.bin_path}\" config --global core.autocrlf \"#{OPTIONS['core.autocrlf']}\"")
        )
        for_more_information(
          see_installation_guide_section 'GitLab'
        )
      end

      private

      # Tries to configure git itself
      #
      # Returns true if all subcommands were successfull (according to their exit code)
      # Returns false if any or all subcommands failed.
      def auto_fix_git_config(options)
        if !@warned_user_not_gitlab
          command_success = options.map do |name, value|
            system(*%W(#{Gitlab.config.git.bin_path} config --global #{name} #{value}))
          end

          command_success.all?
        else
          false
        end
      end
    end
  end
end
