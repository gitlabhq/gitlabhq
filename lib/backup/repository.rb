require 'yaml'

module Backup
  class Repository

    def dump
      prepare

      Project.find_each(batch_size: 1000) do |project|
        $progress.print " * #{project.path_with_namespace} ... "
        path_to_project_repo = path_to_repo(project)
        path_to_project_bundle = path_to_bundle(project)

        # Create namespace dir if missing
        FileUtils.mkdir_p(File.join(backup_repos_path, project.namespace.path)) if project.namespace

        if project.empty_repo?
          $progress.puts "[SKIPPED]".color(:cyan)
        else
          in_path(path_to_project_repo) do |dir|
            FileUtils.mkdir_p(path_to_tars(project))
            cmd = %W(tar -cf #{path_to_tars(project, dir)} -C #{path_to_project_repo} #{dir})
            output, status = Gitlab::Popen.popen(cmd)

            unless status.zero?
              puts "[FAILED]".color(:red)
              puts "failed: #{cmd.join(' ')}"
              puts output
              abort 'Backup failed'
            end
          end

          cmd = %W(#{Gitlab.config.git.bin_path} --git-dir=#{path_to_project_repo} bundle create #{path_to_project_bundle} --all)
          output, status = Gitlab::Popen.popen(cmd)

          if status.zero?
            $progress.puts "[DONE]".color(:green)
          else
            puts "[FAILED]".color(:red)
            puts "failed: #{cmd.join(' ')}"
            puts output
            abort 'Backup failed'
          end
        end

        wiki = ProjectWiki.new(project)
        path_to_wiki_repo = path_to_repo(wiki)
        path_to_wiki_bundle = path_to_bundle(wiki)

        if File.exist?(path_to_wiki_repo)
          $progress.print " * #{wiki.path_with_namespace} ... "
          if wiki.repository.empty?
            $progress.puts " [SKIPPED]".color(:cyan)
          else
            cmd = %W(#{Gitlab.config.git.bin_path} --git-dir=#{path_to_wiki_repo} bundle create #{path_to_wiki_bundle} --all)
            output, status = Gitlab::Popen.popen(cmd)
            if status.zero?
              $progress.puts " [DONE]".color(:green)
            else
              puts " [FAILED]".color(:red)
              puts "failed: #{cmd.join(' ')}"
              puts output
              abort 'Backup failed'
            end
          end
        end
      end
    end

    def restore
      Gitlab.config.repositories.storages.each do |name, path|
        next unless File.exist?(path)

        # Move repos dir to 'repositories.old' dir
        bk_repos_path = File.join(path, '..', 'repositories.old.' + Time.now.to_i.to_s)
        FileUtils.mv(path, bk_repos_path)
        # This is expected from gitlab:check
        FileUtils.mkdir_p(path, mode: 02770)
      end

      Project.find_each(batch_size: 1000) do |project|
        $progress.print " * #{project.path_with_namespace} ... "
        path_to_project_repo = path_to_repo(project)
        path_to_project_bundle = path_to_bundle(project)

        project.ensure_dir_exist

        if File.exists?(path_to_project_bundle)
          cmd = %W(#{Gitlab.config.git.bin_path} clone --bare #{path_to_project_bundle} #{path_to_project_repo})
        else
          cmd = %W(#{Gitlab.config.git.bin_path} init --bare #{path_to_project_repo})
        end

        output, status = Gitlab::Popen.popen(cmd)
        if status.zero?
          $progress.puts "[DONE]".color(:green)
        else
          puts "[FAILED]".color(:red)
          puts "failed: #{cmd.join(' ')}"
          puts output
          abort 'Restore failed'
        end

        in_path(path_to_tars(project)) do |dir|
          cmd = %W(tar -xf #{path_to_tars(project, dir)} -C #{path_to_project_repo} #{dir})

          output, status = Gitlab::Popen.popen(cmd)
          unless status.zero?
            puts "[FAILED]".color(:red)
            puts "failed: #{cmd.join(' ')}"
            puts output
            abort 'Restore failed'
          end
        end

        wiki = ProjectWiki.new(project)
        path_to_wiki_repo = path_to_repo(wiki)
        path_to_wiki_bundle = path_to_bundle(wiki)

        if File.exist?(path_to_wiki_bundle)
          $progress.print " * #{wiki.path_with_namespace} ... "

          # If a wiki bundle exists, first remove the empty repo
          # that was initialized with ProjectWiki.new() and then
          # try to restore with 'git clone --bare'.
          FileUtils.rm_rf(path_to_wiki_repo)
          cmd = %W(#{Gitlab.config.git.bin_path} clone --bare #{path_to_wiki_bundle} #{path_to_wiki_repo})

          output, status = Gitlab::Popen.popen(cmd)
          if status.zero?
            $progress.puts " [DONE]".color(:green)
          else
            puts " [FAILED]".color(:red)
            puts "failed: #{cmd.join(' ')}"
            puts output
            abort 'Restore failed'
          end
        end
      end

      $progress.print 'Put GitLab hooks in repositories dirs'.color(:yellow)
      cmd = %W(#{Gitlab.config.gitlab_shell.path}/bin/create-hooks) + repository_storage_paths_args

      output, status = Gitlab::Popen.popen(cmd)
      if status.zero?
        $progress.puts " [DONE]".color(:green)
      else
        puts " [FAILED]".color(:red)
        puts "failed: #{cmd}"
        puts output
      end
    end

    protected

    def path_to_repo(project)
      project.repository.path_to_repo
    end

    def path_to_bundle(project)
      File.join(backup_repos_path, project.path_with_namespace + '.bundle')
    end

    def path_to_tars(project, dir = nil)
      path = File.join(backup_repos_path, project.path_with_namespace)

      if dir
        File.join(path, "#{dir}.tar")
      else
        path
      end
    end

    def backup_repos_path
      File.join(Gitlab.config.backup.path, 'repositories')
    end

    def in_path(path)
      return unless Dir.exist?(path)

      dir_entries = Dir.entries(path)
      %w[annex custom_hooks].each do |entry|
        yield(entry) if dir_entries.include?(entry)
      end
    end

    def prepare
      FileUtils.rm_rf(backup_repos_path)
      # Ensure the parent dir of backup_repos_path exists
      FileUtils.mkdir_p(Gitlab.config.backup.path)
      # Fail if somebody raced to create backup_repos_path before us
      FileUtils.mkdir(backup_repos_path, mode: 0700)
    end

    def silent
      {err: '/dev/null', out: '/dev/null'}
    end

    private

    def repository_storage_paths_args
      Gitlab.config.repositories.storages.values
    end
  end
end
