namespace :gitlab do
  namespace :workhorse do
    desc "GitLab | Install or upgrade gitlab-workhorse"
    task :install, [:dir] => :environment do |t, args|
      warn_user_is_not_gitlab
      unless args.dir.present?
        abort %(Please specify the directory where you want to install gitlab-workhorse:\n  rake "gitlab:workhorse:install[/home/git/gitlab-workhorse]")
      end

      tag = "v#{Gitlab::Workhorse.version}"
      repo = 'https://gitlab.com/gitlab-org/gitlab-workhorse.git'

      checkout_or_clone_tag(tag: tag, repo: repo, target_dir: args.dir)

      _, status = Gitlab::Popen.popen(%w[which gmake])
      command = status.zero? ? 'gmake' : 'make'

      Dir.chdir(args.dir) do
        run_command!([command])
      end
    end
  end
end
