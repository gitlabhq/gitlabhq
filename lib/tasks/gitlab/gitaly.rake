namespace :gitlab do
  namespace :gitaly do
    desc "GitLab | Install or upgrade gitaly"
    task :install, [:dir] => :environment do |t, args|
      warn_user_is_not_gitlab
      unless args.dir.present?
        abort %(Please specify the directory where you want to install gitaly:\n  rake "gitlab:gitaly:install[/home/git/gitaly]")
      end

      tag = "v#{Gitlab::GitalyClient.expected_server_version}"
      repo = 'https://gitlab.com/gitlab-org/gitaly.git'

      checkout_or_clone_tag(tag: tag, repo: repo, target_dir: args.dir)

      _, status = Gitlab::Popen.popen(%w[which gmake])
      command = status.zero? ? 'gmake' : 'make'

      Dir.chdir(args.dir) do
        run_command!([command])
      end
    end
  end
end
