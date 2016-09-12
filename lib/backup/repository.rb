require 'yaml'

module Backup
  class Repository
    def dump
      prepare

      Project.find_each(batch_size: 1000) do |project|
        $progress.print " * #{project.path_with_namespace} ... "

        # Create namespace dir if missing
        FileUtils.mkdir_p(File.join(backup_repos_path, project.namespace.path)) if project.namespace

        if project.empty_repo?
          $progress.puts "[SKIPPED]".color(:cyan)
        else
          cmd = %W(tar -cf #{path_to_bundle(project)} -C #{path_to_repo(project)} .)
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

        if File.exist?(path_to_repo(wiki))
          $progress.print " * #{wiki.path_with_namespace} ... "
          if wiki.repository.empty?
            $progress.puts " [SKIPPED]".color(:cyan)
          else
            cmd = %W(#{Gitlab.config.git.bin_path} --git-dir=#{path_to_repo(wiki)} bundle create #{path_to_bundle(wiki)} --all)
            output, status = Gitlab::Popen.popen(cmd)
            if status.zero?
              $progress.puts " [DONE]".color(:green)
            else
              puts " [FAILED]".color(:red)
              puts "failed: #{cmd.join(' ')}"
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

        project.ensure_dir_exist

        if File.exist?(path_to_bundle(project))
          FileUtils.mkdir_p(path_to_repo(project))
          cmd = %W(tar -xf #{path_to_bundle(project)} -C #{path_to_repo(project)})
        else
          cmd = %W(#{Gitlab.config.git.bin_path} init --bare #{path_to_repo(project)})
        end

        if system(*cmd, silent)
          $progress.puts "[DONE]".color(:green)
        else
          puts "[FAILED]".color(:red)
          puts "failed: #{cmd.join(' ')}"
          abort 'Restore failed'
        end

        wiki = ProjectWiki.new(project)

        if File.exist?(path_to_bundle(wiki))
          $progress.print " * #{wiki.path_with_namespace} ... "

          # If a wiki bundle exists, first remove the empty repo
          # that was initialized with ProjectWiki.new() and then
          # try to restore with 'git clone --bare'.
          FileUtils.rm_rf(path_to_repo(wiki))
          cmd = %W(#{Gitlab.config.git.bin_path} clone --bare #{path_to_bundle(wiki)} #{path_to_repo(wiki)})

          if system(*cmd, silent)
            $progress.puts " [DONE]".color(:green)
          else
            puts " [FAILED]".color(:red)
            puts "failed: #{cmd.join(' ')}"
            abort 'Restore failed'
          end
        end
      end

      $progress.print 'Put GitLab hooks in repositories dirs'.color(:yellow)
      cmd = %W(#{Gitlab.config.gitlab_shell.path}/bin/create-hooks) + repository_storage_paths_args
      if system(*cmd)
        $progress.puts " [DONE]".color(:green)
      else
        puts " [FAILED]".color(:red)
        puts "failed: #{cmd}"
      end

    end

    protected

    def path_to_repo(project)
      project.repository.path_to_repo
    end

    def path_to_bundle(project)
      File.join(backup_repos_path, project.path_with_namespace + ".bundle")
    end

    def backup_repos_path
      File.join(Gitlab.config.backup.path, "repositories")
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
