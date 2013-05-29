require 'yaml'

module Backup
  class Repository
    attr_reader :repos_path

    def dump
      prepare

      Project.find_each(batch_size: 1000) do |project|
        print " * #{project.path_with_namespace} ... "

        if project.empty_repo?
          puts "[SKIPPED]".cyan
          next
        end

        # Create namespace dir if missing
        FileUtils.mkdir_p(File.join(backup_repos_path, project.namespace.path)) if project.namespace

        if system("cd #{path_to_repo(project)} > /dev/null 2>&1 && git bundle create #{path_to_bundle(project)} --all > /dev/null 2>&1")
          puts "[DONE]".green
        else
          puts "[FAILED]".red
        end

        wiki = GollumWiki.new(project)

        if File.exists?(path_to_repo(wiki))
          print " * #{wiki.path_with_namespace} ... "
          if system("cd #{path_to_repo(wiki)} > /dev/null 2>&1 && git bundle create #{path_to_bundle(wiki)} --all > /dev/null 2>&1")
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

        if system("git clone --bare #{path_to_bundle(project)} #{path_to_repo(project)} > /dev/null 2>&1")
          puts "[DONE]".green
        else
          puts "[FAILED]".red
        end

        wiki = GollumWiki.new(project)

        if File.exists?(path_to_bundle(wiki))
          print " * #{wiki.path_with_namespace} ... "
          if system("git clone --bare #{path_to_bundle(wiki)} #{path_to_repo(wiki)} > /dev/null 2>&1")
            puts " [DONE]".green
          else
            puts " [FAILED]".red
          end
        end
      end

      print 'Put GitLab hooks in repositories dirs'.yellow
      gitlab_shell_user_home = File.expand_path("~#{Gitlab.config.gitlab_shell.ssh_user}")
      if system("#{gitlab_shell_user_home}/gitlab-shell/support/rewrite-hooks.sh #{Gitlab.config.gitlab_shell.repos_path}")
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
  end
end
