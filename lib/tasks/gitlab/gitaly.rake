# frozen_string_literal: true

namespace :gitlab do
  namespace :gitaly do
    desc 'GitLab | Gitaly | Clone and checkout gitaly'
    task :clone, [:dir, :storage_path, :repo] => :gitlab_environment do |t, args|
      warn_user_is_not_gitlab

      unless args.dir.present? && args.storage_path.present?
        abort %(Please specify the directory where you want to install gitaly and the path for the default storage
Usage: rake "gitlab:gitaly:install[/installation/dir,/storage/path]")
      end

      args.with_defaults(repo: 'https://gitlab.com/gitlab-org/gitaly.git')

      version = Gitlab::GitalyClient.expected_server_version

      checkout_or_clone_version(version: version, repo: args.repo, target_dir: args.dir, clone_opts: %w[--depth 1])
    end

    desc 'GitLab | Gitaly | Install or upgrade gitaly'
    task :install, [:dir, :storage_path, :repo] => [:gitlab_environment, 'gitlab:gitaly:clone'] do |t, args|
      warn_user_is_not_gitlab

      storage_paths = { 'default' => args.storage_path }
      Gitlab::SetupHelper::Gitaly.create_configuration(args.dir, storage_paths)

      Dir.chdir(args.dir) do
        output, status = Gitlab::Popen.popen([make_cmd, 'clean', 'all'])
        raise "Gitaly failed to compile: #{output}" unless status&.zero?
      end
    end

    desc 'GitLab | Gitaly | Update removed storage projects'
    task :update_removed_storage_projects,
      [:removed_storage_name, :target_storage_name] => :gitlab_environment do |t, args|
      warn_user_is_not_gitlab

      unless args.removed_storage_name.present? && args.target_storage_name.present?
        abort %(Please specify the names of the removed storage and the storage to move projects to
Usage: rake "gitlab:gitaly:update_removed_storage_projects[removed_storage_name,target_storage_name]")
      end

      project_ct = Project.where(repository_storage: args.removed_storage_name).length

      if ENV['APPLY'] == '1'
        puts "Updating #{project_ct} projects from storage " \
          "#{args.removed_storage_name} to #{args.target_storage_name} in the Rails database."

        Project
          .where(repository_storage: args.removed_storage_name)
          .update_all(repository_storage: args.target_storage_name)
      else
        puts "DRY RUN: would have updated #{project_ct} projects from storage " \
          "#{args.removed_storage_name} to #{args.target_storage_name} in the Rails database."
        puts "Run again with environment variable 'APPLY=1' to perform the change."
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
