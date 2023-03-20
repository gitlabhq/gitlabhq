# frozen_string_literal: true

namespace :gitlab do
  require_relative Rails.root.join('metrics_server', 'dependencies')
  require_relative Rails.root.join('metrics_server', 'metrics_server')

  namespace :metrics_exporter do
    REPO = 'https://gitlab.com/gitlab-org/gitlab-metrics-exporter.git'

    desc "GitLab | Metrics Exporter | Install or upgrade gitlab-metrics-exporter"
    task :install, [:dir] => :gitlab_environment do |t, args|
      unless args.dir.present?
        abort %(Please specify the directory where you want to install the exporter
Usage: rake "gitlab:metrics_exporter:install[/installation/dir]")
      end

      version = ENV['GITLAB_METRICS_EXPORTER_VERSION'] || MetricsServer.version
      make = Gitlab::Utils.which('gmake') || Gitlab::Utils.which('make')

      abort "Couldn't find a 'make' binary" unless make

      checkout_or_clone_version(version: version, repo: REPO, target_dir: args.dir, clone_opts: %w[--depth 1])

      Dir.chdir(args.dir) { run_command!([make]) }
    end
  end
end
