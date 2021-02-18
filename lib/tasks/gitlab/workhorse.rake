# frozen_string_literal: true

namespace :gitlab do
  namespace :workhorse do
    desc "GitLab | Workhorse | Install or upgrade gitlab-workhorse"
    task :install, [:dir, :repo] => :gitlab_environment do |t, args|
      warn_user_is_not_gitlab

      unless args.dir.present?
        abort %(Please specify the directory where you want to install gitlab-workhorse:\n  rake "gitlab:workhorse:install[/home/git/gitlab-workhorse]")
      end

      # It used to be the case that the binaries in the target directory match
      # the source code. An administrator could run `make` to rebuild the
      # binaries for instance. Or they could read the source code, or run `git
      # log` to see what changed. Or they could patch workhorse for some
      # reason and recompile it. None of those things make sense anymore once
      # the transition in https://gitlab.com/groups/gitlab-org/-/epics/4826 is
      # done: there would be an outdated copy of the workhorse source code for
      # the administrator to poke at.
      #
      # To prevent this possible confusion and make clear what is going on, we
      # have created a special branch `workhorse-move-notice` in the old
      # gitlab-workhorse repository which contains no Go files anymore, just a
      # README explaining what is going on. See:
      # https://gitlab.com/gitlab-org/gitlab-workhorse/tree/workhorse-move-notice
      #
      args.with_defaults(repo: 'https://gitlab.com/gitlab-org/gitlab-workhorse.git')
      checkout_or_clone_version(version: 'workhorse-move-notice', repo: args.repo, target_dir: args.dir, clone_opts: %w[--depth 1])

      Gitlab::SetupHelper::Workhorse.compile_into(args.dir)
    end
  end
end
