require_relative 'gitolite_config'

module Gitlab
  class Gitolite
    class AccessDenied < StandardError; end

    def config
      Gitlab::GitoliteConfig.new
    end

    def set_key key_id, key_content, projects
      config.apply do |config|
        config.write_key(key_id, key_content)
        config.update_projects(projects)
      end
    end

    def remove_key key_id, projects
      config.apply do |config|
        config.rm_key(key_id)
        config.update_projects(projects)
      end
    end

    def update_repository project
      config.update_project!(project)
    end

    def move_repository(old_repo, project)
      config.apply do |config|
        config.clean_repo(old_repo)
        config.update_project(project)
      end
    end

    def remove_repository project
      config.destroy_project!(project)
    end

    def url_to_repo path
      Gitlab.config.gitolite.ssh_path_prefix + "#{path}.git"
    end

    def enable_automerge
      config.admin_all_repo!
    end

    def update_repositories projects
      config.apply do |config|
        config.update_projects(projects)
      end
    end

    alias_method :create_repository, :update_repository
  end
end
