namespace :gitlab do
  namespace :workhorse do
    desc "GitLab | Install or upgrade gitlab-workhorse"
    task :install, [:dir, :repo] => :gitlab_environment do |t, args|
      warn_user_is_not_gitlab

      unless args.dir.present?
        abort %(Please specify the directory where you want to install gitlab-workhorse:\n  rake "gitlab:workhorse:install[/home/git/gitlab-workhorse]")
      end

      args.with_defaults(repo: 'https://gitlab.com/gitlab-org/gitlab-workhorse.git')

      version = Gitlab::Workhorse.version

      checkout_or_clone_version(version: version, repo: args.repo, target_dir: args.dir)

      _, status = Gitlab::Popen.popen(%w[which gmake])
      command = status.zero? ? 'gmake' : 'make'

      Dir.chdir(args.dir) do
        run_command!([command])
      end
    end
  end
end
