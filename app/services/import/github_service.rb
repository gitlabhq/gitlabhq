# frozen_string_literal: true

module Import
  class GithubService < Import::BaseService
    attr_accessor :client
    attr_reader :params, :current_user

    def execute(access_params, provider)
      if blocked_url?
        return log_and_return_error("Invalid URL: #{url}", :bad_request)
      end

      unless authorized?
        return error(_('This namespace has already been taken! Please choose another one.'), :unprocessable_entity)
      end

      project = create_project(access_params, provider)

      if project.persisted?
        success(project)
      else
        error(project_save_error(project), :unprocessable_entity)
      end
    rescue Octokit::Error => e
      log_error(e)
    end

    def create_project(access_params, provider)
      Gitlab::LegacyGithubImport::ProjectCreator.new(
        repo,
        project_name,
        target_namespace,
        current_user,
        type: provider,
        **access_params).execute(extra_project_attrs)
    end

    def repo
      @repo ||= client.repository(params[:repo_id].to_i)
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

    def url
      @url ||= params[:github_hostname]
    end

    def allow_local_requests?
      Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
    end

    def blocked_url?
      Gitlab::UrlBlocker.blocked_url?(
        url,
        {
          allow_localhost: allow_local_requests?,
          allow_local_network: allow_local_requests?,
          schemes: %w(http https)
        }
      )
    end

    private

    def log_error(exception)
      Gitlab::Import::Logger.error(
        message: 'Import failed due to a GitHub error',
        status: exception.response_status,
        error: exception.response_body
      )

      error(_('Import failed due to a GitHub error: %{original}') % { original: exception.response_body }, :unprocessable_entity)
    end
  end
end

Import::GithubService.prepend_if_ee('EE::Import::GithubService')
