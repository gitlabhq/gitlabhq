# frozen_string_literal: true

module Import
  class GithubService < Import::BaseService
    attr_accessor :client
    attr_reader :params, :current_user

    def execute(access_params, provider)
      unless authorized?
        return error(_('This namespace has already been taken! Please choose another one.'), :unprocessable_entity)
      end

      project = Gitlab::LegacyGithubImport::ProjectCreator
                  .new(repo, project_name, target_namespace, current_user, access_params, type: provider)
                  .execute(extra_project_attrs)

      if project.persisted?
        success(project)
      else
        error(project_save_error(project), :unprocessable_entity)
      end
    end

    def repo
      @repo ||= client.repo(params[:repo_id].to_i)
    end

    def project_name
      @project_name ||= params[:new_name].presence || repo.name
    end

    def namespace_path
      @namespace_path ||= params[:target_namespace].presence || current_user.namespace_path
    end

    def target_namespace
      @target_namespace ||= find_or_create_namespace(namespace_path, current_user.namespace_path)
    end

    def extra_project_attrs
      {}
    end

    def authorized?
      can?(current_user, :create_projects, target_namespace)
    end
  end
end
