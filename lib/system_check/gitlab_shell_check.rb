# frozen_string_literal: true

module SystemCheck
  # Used by gitlab:gitlab_shell:check rake task
  class GitlabShellCheck < BaseCheck
    set_name 'GitLab Shell:'

    def multi_check
      check_gitlab_shell
      check_gitlab_shell_self_test
    end

    private

    def check_gitlab_shell
      required_version = Gitlab::VersionInfo.parse(Gitlab::Shell.version_required)
      current_version = Gitlab::VersionInfo.parse(gitlab_shell_version)

      $stdout.print "GitLab Shell version >= #{required_version} ? ... "
      if current_version.valid? && required_version <= current_version
        $stdout.puts Rainbow("OK (#{current_version})").green
      else
        $stdout.puts Rainbow("FAIL. Please update gitlab-shell to #{required_version} from #{current_version}").red
      end
    end

    def check_gitlab_shell_self_test
      gitlab_shell_repo_base = gitlab_shell_path
      check_cmd = File.expand_path('bin/gitlab-shell-check', gitlab_shell_repo_base)
      $stdout.puts "Running #{check_cmd}"

      if system(check_cmd, chdir: gitlab_shell_repo_base)
        $stdout.puts Rainbow('gitlab-shell self-check successful').green
      else
        $stdout.puts Rainbow('gitlab-shell self-check failed').red
        try_fixing_it(
          'Make sure GitLab is running;',
          'Check the gitlab-shell configuration file:',
          sudo_gitlab("editor #{File.expand_path('config.yml', gitlab_shell_repo_base)}")
        )
        fix_and_rerun
      end
    end

    # Helper methods
    ########################

    def gitlab_shell_path
      Gitlab.config.gitlab_shell.path
    end

    def gitlab_shell_version
      Gitlab::Shell.version
    end
  end
end
