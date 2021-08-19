# frozen_string_literal: true

namespace :gitlab do
  namespace :gitaly do
    desc 'Installs gitaly for running tests within gitlab-development-kit'
    task :test_install, [:dir, :storage_path, :repo] => :gitlab_environment do |t, args|
      inside_gdk = Rails.env.test? && File.exist?(Rails.root.join('../GDK_ROOT'))

      if ENV['FORCE_GITALY_INSTALL'] || !inside_gdk
        Rake::Task["gitlab:gitaly:install"].invoke(*args)

        next
      end

      gdk_gitaly_dir = ENV.fetch('GDK_GITALY', Rails.root.join('../gitaly'))

      # Our test setup expects a git repo, so clone rather than copy
      version = Gitlab::GitalyClient.expected_server_version
      checkout_or_clone_version(version: version, repo: gdk_gitaly_dir, target_dir: args.dir, clone_opts: %w[--depth 1])

      # We assume the GDK gitaly already compiled binaries
      build_dir = File.join(gdk_gitaly_dir, '_build')
      FileUtils.cp_r(build_dir, args.dir)

      # We assume the GDK gitaly already ran bundle install
      bundle_dir = File.join(gdk_gitaly_dir, 'ruby', '.bundle')
      FileUtils.cp_r(bundle_dir, File.join(args.dir, 'ruby'))

      # For completeness we copy this for gitaly's make target
      ruby_bundle_file = File.join(gdk_gitaly_dir, '.ruby-bundle')
      FileUtils.cp_r(ruby_bundle_file, args.dir)

      gitaly_binary = File.join(build_dir, 'bin', 'gitaly')
      warn_gitaly_out_of_date!(gitaly_binary, version)
    rescue Errno::ENOENT => e
      puts "Could not copy files, did you run `gdk update`? Error: #{e.message}"

      raise
    end

    desc 'GitLab | Gitaly | Install or upgrade gitaly'
    task :install, [:dir, :storage_path, :repo] => :gitlab_environment do |t, args|
      warn_user_is_not_gitlab

      unless args.dir.present? && args.storage_path.present?
        abort %(Please specify the directory where you want to install gitaly and the path for the default storage
Usage: rake "gitlab:gitaly:install[/installation/dir,/storage/path]")
      end

      args.with_defaults(repo: 'https://gitlab.com/gitlab-org/gitaly.git')

      version = Gitlab::GitalyClient.expected_server_version

      checkout_or_clone_version(version: version, repo: args.repo, target_dir: args.dir, clone_opts: %w[--depth 1])

      storage_paths = { 'default' => args.storage_path }
      Gitlab::SetupHelper::Gitaly.create_configuration(args.dir, storage_paths)

      # In CI we run scripts/gitaly-test-build
      next if ENV['CI'].present?

      Dir.chdir(args.dir) do
        Bundler.with_original_env do
          env = { "RUBYOPT" => nil, "BUNDLE_GEMFILE" => nil }

          if Rails.env.test?
            env["GEM_HOME"] = Bundler.bundle_path.to_s
            env["BUNDLE_DEPLOYMENT"] = 'false'
          end

          Gitlab::Popen.popen([make_cmd], nil, env)
        end
      end
    end

    def make_cmd
      _, status = Gitlab::Popen.popen(%w[which gmake])
      status == 0 ? 'gmake' : 'make'
    end

    def warn_gitaly_out_of_date!(gitaly_binary, expected_version)
      binary_version, exit_status = Gitlab::Popen.popen(%W[#{gitaly_binary} -version])

      raise "Failed to run `#{gitaly_binary} -version`" unless exit_status == 0

      binary_version = binary_version.strip

      # See help for `git describe` for format
      git_describe_sha = /g([a-f0-9]{5,40})\z/
      match = binary_version.match(git_describe_sha)

      # Just skip if the version does not have a sha component
      return unless match

      return if expected_version.start_with?(match[1])

      puts "WARNING: #{binary_version.strip} does not exactly match repository version #{expected_version}"
    end
  end
end
