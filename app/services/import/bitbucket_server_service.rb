# frozen_string_literal: true

module Import
  class BitbucketServerService < Import::BaseService
    attr_reader :client, :params, :current_user

    def execute(credentials)
      if blocked_url?
        return log_and_return_error("Invalid URL: #{url}", :bad_request)
      end

      unless authorized?
        return log_and_return_error("You don't have permissions to import this project", :unauthorized)
      end

      unless repo
        return log_and_return_error("Project %{project_repo} could not be found" % { project_repo: "#{project_key}/#{repo_slug}" }, :unprocessable_entity)
      end

      project = create_project(credentials)

      track_access_level('bitbucket')

      if project.persisted?
        success(project)
      elsif project.errors[:import_source_disabled].present?
        error(project.errors[:import_source_disabled], :forbidden)
      else
        log_and_return_error(project_save_error(project), :unprocessable_entity)
      end
    rescue BitbucketServer::Connection::ConnectionError => e
      log_and_return_error("Import failed due to a BitBucket Server error: #{e}", :bad_request)
    end

    private

    def create_project(credentials)
      Gitlab::BitbucketServerImport::ProjectCreator.new(
        project_key,
        repo_slug,
        repo,
        project_name,
        target_namespace,
        current_user,
        credentials,
        timeout_strategy
      ).execute
    end

    def repo
      @repo ||= client.repo(project_key, repo_slug)
    end

    def project_name
      @project_name ||= params[:new_name].presence || repo.name
    end

    def namespace_path
      @namespace_path ||= params[:new_namespace].presence || current_user.namespace_path
    end

    def target_namespace
      @target_namespace ||= find_or_create_namespace(namespace_path, current_user.namespace_path)
    end

    def repo_slug
      @repo_slug ||= params[:bitbucket_server_repo]
    end

    def project_key
      @project_key ||= params[:bitbucket_server_project]
    end

    def url
      @url ||= params[:bitbucket_server_url]
    end

    def timeout_strategy
      @timeout_strategy ||= params[:timeout_strategy] || ProjectImportData::PESSIMISTIC_TIMEOUT
    end

    def allow_local_requests?
      Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
    end

    def blocked_url?
      Gitlab::HTTP_V2::UrlBlocker.blocked_url?(
        url,
        allow_localhost: allow_local_requests?,
        allow_local_network: allow_local_requests?,
        schemes: %w[http https],
        deny_all_requests_except_allowed: Gitlab::CurrentSettings.deny_all_requests_except_allowed?,
        outbound_local_requests_allowlist: Gitlab::CurrentSettings.outbound_local_requests_whitelist # rubocop:disable Naming/InclusiveLanguage -- existing setting
      )
    end

    def log_and_return_error(message, error_type)
      log_error(message)
      error(_(message), error_type)
    end

    def log_error(message)
      ::Import::Framework::Logger.error(
        message: 'Import failed due to a BitBucket Server error',
        error: message
      )
    end
  end
end
