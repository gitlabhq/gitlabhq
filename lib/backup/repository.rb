require 'yaml'

module Backup
  class Repository
    attr_reader :repos_path

    def dump
      prepare

      Project.find_each(batch_size: 1000) do |project|
        print " * #{project.path_with_namespace} ... "

        # Create namespace dir if missing
        FileUtils.mkdir_p(File.join(backup_repos_path, project.namespace.path)) if project.namespace

        if project.empty_repo?
          puts "[SKIPPED]".cyan
        elsif system(*%W(git --git-dir=#{path_to_repo(project)} bundle create #{path_to_bundle(project)} --all), silent)
          puts "[DONE]".green
        else
          puts "[FAILED]".red
        end

        wiki = ProjectWiki.new(project)

        if File.exists?(path_to_repo(wiki))
          print " * #{wiki.path_with_namespace} ... "
          if wiki.empty?
            puts " [SKIPPED]".cyan
          elsif system(*%W(git --git-dir=#{path_to_repo(wiki)} bundle create #{path_to_bundle(wiki)} --all), silent)
            puts " [DONE]".green
          else
            puts " [FAILED]".red
          end
        end
      end
    end

    def restore
      if File.exists?(repos_path)
        # Move repos dir to 'repositories.old' dir
        bk_repos_path = File.join(repos_path, '..', 'repositories.old.' + Time.now.to_i.to_s)
        FileUtils.mv(repos_path, bk_repos_path)
      end

      FileUtils.mkdir_p(repos_path)

      Project.find_each(batch_size: 1000) do |project|
        print "#{project.path_with_namespace} ... "

        project.namespace.ensure_dir_exist if project.namespace

        if system(*%W(git clone --bare #{path_to_bundle(project)} #{path_to_repo(project)}), silent)
          puts "[DONE]".green
        else
          puts "[FAILED]".red
        end

        wiki = ProjectWiki.new(project)

        if File.exists?(path_to_bundle(wiki))
          print " * #{wiki.path_with_namespace} ... "
          if system(*%W(git clone --bare #{path_to_bundle(wiki)} #{path_to_repo(wiki)}), silent)
            puts " [DONE]".green
          else
            puts " [FAILED]".red
          end
        end
      end

      print 'Put GitLab hooks in repositories dirs'.yellow
      if system("#{Gitlab.config.gitlab_shell.path}/support/rewrite-hooks.sh", Gitlab.config.gitlab_shell.repos_path)
        puts " [DONE]".green
      else
        puts " [FAILED]".red
      end

    end

    protected

    def path_to_repo(project)
      File.join(repos_path, project.path_with_namespace + '.git')
    end

    def path_to_bundle(project)
      File.join(backup_repos_path, project.path_with_namespace + ".bundle")
    end

    def repos_path
      Gitlab.config.gitlab_shell.repos_path
    end

    def backup_repos_path
      File.join(Gitlab.config.backup.path, "repositories")
    end

    def prepare
      FileUtils.rm_rf(backup_repos_path)
      FileUtils.mkdir_p(backup_repos_path)
    end

    def silent
      {err: '/dev/null', out: '/dev/null'}
    end
  end
end
