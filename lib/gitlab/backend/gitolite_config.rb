require 'gitolite'
require 'timeout'
require 'fileutils'

module Gitlab
  class GitoliteConfig
    class PullError < StandardError; end
    class PushError < StandardError; end

    attr_reader :config_tmp_dir, :ga_repo, :conf

    def config_tmp_dir
      @config_tmp_dir ||= Rails.root.join('tmp',"gitlabhq-gitolite-#{Time.now.to_i}")
    end

    def ga_repo
      @ga_repo ||= ::Gitolite::GitoliteAdmin.new(
        File.join(config_tmp_dir,'gitolite'),
        conf: Gitlab.config.gitolite.config_file
      )
    end

    def apply
      Timeout::timeout(30) do
        File.open(Rails.root.join('tmp', "gitlabhq-gitolite.lock"), "w+") do |f|
          begin
            # Set exclusive lock
            # to prevent race condition
            f.flock(File::LOCK_EX)

            # Pull gitolite-admin repo
            # in tmp dir before do any changes
            pull(config_tmp_dir)

            # Build ga_repo object and @conf
            # to access gitolite-admin configuration
            @conf = ga_repo.config

            # Do any changes
            # in gitolite-admin
            # config here
            yield(self)

            # Save changes in
            # gitolite-admin repo
            # before push it
            ga_repo.save

            # Push gitolite-admin repo
            # to apply all changes
            push(config_tmp_dir)
          ensure
            # Remove tmp dir
            # removing the gitolite folder first is important to avoid
            # NFS issues.
            FileUtils.rm_rf(File.join(config_tmp_dir, 'gitolite'))

            # Remove parent tmp dir
            FileUtils.rm_rf(config_tmp_dir)

            # Unlock so other task can access
            # gitolite configuration
            f.flock(File::LOCK_UN)
          end
        end
      end
    rescue PullError => ex
      log("Pull error ->  " + ex.message)
      raise Gitolite::AccessDenied, ex.message

    rescue PushError => ex
      log("Push error ->  " + " " + ex.message)
      raise Gitolite::AccessDenied, ex.message

    rescue Exception => ex
      log(ex.class.name + " " + ex.message)
      raise Gitolite::AccessDenied.new("gitolite timeout")
    end

    def log message
      Gitlab::GitLogger.error(message)
    end

    def destroy_project(project)
      FileUtils.rm_rf(project.path_to_repo)
      conf.rm_repo(project.path_with_namespace)
    end

    def clean_repo repo_name
      conf.rm_repo(repo_name)
    end

    def destroy_project!(project)
      apply do |config|
        config.destroy_project(project)
      end
    end

    def write_key(id, key)
      File.open(File.join(config_tmp_dir, 'gitolite/keydir',"#{id}.pub"), 'w') do |f|
        f.write(key.gsub(/\n/,''))
      end
    end

    def rm_key(user)
      key_path = File.join(config_tmp_dir, 'gitolite/keydir', "#{user}.pub")
      ga_key = ::Gitolite::SSHKey.from_file(key_path)
      ga_repo.rm_key(ga_key)
    end

    # update or create
    def update_project(project)
      repo = update_project_config(project, conf)
      conf.add_repo(repo, true)
    end

    def update_project!( project)
      apply do |config|
        config.update_project(project)
      end
    end

    # Updates many projects and uses project.path_with_namespace as the repo path
    # An order of magnitude faster than update_project
    def update_projects(projects)
      projects.each do |project|
        repo = update_project_config(project, conf)
        conf.add_repo(repo, true)
      end
    end

    def update_project_config(project, conf)
      repo_name = project.path_with_namespace

      repo = if conf.has_repo?(repo_name)
               conf.get_repo(repo_name)
             else
               ::Gitolite::Config::Repo.new(repo_name)
             end

      name_readers = project.repository_readers
      name_writers = project.repository_writers
      name_masters = project.repository_masters

      pr_br = project.protected_branches.map(&:name).join("$ ")

      repo.clean_permissions

      # Deny access to protected branches for writers
      unless name_writers.blank? || pr_br.blank?
        repo.add_permission("-", pr_br.strip + "$ ", name_writers)
      end

      # Add read permissions
      repo.add_permission("R", "", name_readers) unless name_readers.blank?

      # Add write permissions
      repo.add_permission("RW+", "", name_writers) unless name_writers.blank?
      repo.add_permission("RW+", "", name_masters) unless name_masters.blank?

      # Add sharedRepository config
      repo.set_git_config("core.sharedRepository", "0660")

      repo
    end

    # Enable access to all repos for gitolite admin.
    # We use it for accept merge request feature
    def admin_all_repo
      owner_name = Gitlab.config.gitolite.admin_key

      # @ALL repos premission for gitolite owner
      repo_name = "@all"
      repo = if conf.has_repo?(repo_name)
               conf.get_repo(repo_name)
             else
               ::Gitolite::Config::Repo.new(repo_name)
             end

      repo.add_permission("RW+", "", owner_name)
      conf.add_repo(repo, true)
    end

    def admin_all_repo!
      apply { |config| config.admin_all_repo }
    end

    private

    def pull tmp_dir
      Dir.mkdir tmp_dir
      `git clone #{Gitlab.config.gitolite.admin_uri} #{tmp_dir}/gitolite`

      unless File.exists?(File.join(tmp_dir, 'gitolite', 'conf', 'gitolite.conf'))
        raise PullError, "unable to clone gitolite-admin repo"
      end
    end

    def push tmp_dir
      Dir.chdir(File.join(tmp_dir, "gitolite"))
      raise "Git add failed." unless system('git add -A')
      system('git commit -m "GitLab"') # git commit returns 0 on success, and 1 if there is nothing to commit
      raise "Git commit failed." unless [0,1].include? $?.exitstatus

      if system('git push')
        Dir.chdir(Rails.root)
      else
        raise PushError, "unable to push gitolite-admin repo"
      end
    end
  end
end

