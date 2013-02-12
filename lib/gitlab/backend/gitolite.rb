require_relative 'gitolite_config'

module Gitlab
  class Gitolite
    class AccessDenied < StandardError; end

    def config
      Gitlab::GitoliteConfig.new
    end

    # Update gitolite config with new key
    #
    # Ex.
    #   set_key("m_gitlab_com_12343", "sha-rsa ...", [2, 3, 6])
    #
    def set_key(key_id, key_content, project_ids)
      projects = Project.where(id: project_ids)

      config.apply do |config|
        config.write_key(key_id, key_content)
        config.update_projects(projects)
      end
    end

    # Remove ssh key from gitolite config
    #
    # Ex.
    #   remove_key("m_gitlab_com_12343", [2, 3, 6])
    #
    def remove_key(key_id, project_ids)
      projects = Project.where(id: project_ids)

      config.apply do |config|
        config.rm_key(key_id)
        config.update_projects(projects)
      end
    end

    # Update project config in gitolite by project id
    #
    # Ex.
    #   update_repository(23)
    #
    def update_repository(project_id)
      project = Project.find(project_id)
      config.update_project!(project)
    end

    def move_repository(old_repo, project)
      config.apply do |config|
        config.clean_repo(old_repo)
        config.update_project(project)
      end
    end

    # Remove repository from gitolite
    #
    # name - project path with namespace
    #
    # Ex.
    #   remove_repository("gitlab/gitlab-ci")
    #
    def remove_repository(name)
      config.destroy_project!(name)
    end

    # Update projects configs in gitolite by project ids
    #
    # Ex.
    #   update_repositories([1, 4, 6])
    #
    def update_repositories(project_ids)
      projects = Project.where(id: project_ids)

      config.apply do |config|
        config.update_projects(projects)
      end
    end

    def url_to_repo path
      Gitlab.config.gitolite.ssh_path_prefix + "#{path}.git"
    end

    def enable_automerge
      config.admin_all_repo!
    end

    alias_method :create_repository, :update_repository
  end
end
