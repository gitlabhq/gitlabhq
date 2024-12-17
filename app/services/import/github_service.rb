# frozen_string_literal: true

module Import
  class GithubService < Import::BaseService
    include ActiveSupport::NumberHelper
    include SafeFormatHelper

    attr_accessor :client
    attr_reader :params, :current_user

    def execute(access_params, provider)
      context_error = validate_context
      return context_error if context_error

      if provider == :github # we skip access token validation for Gitea importer calls
        access_token_error = validate_access_token
        return access_token_error if access_token_error
      end

      project = create_project(access_params, provider)
      track_access_level(provider.to_s) # provider may be :gitea

      if project.persisted?
        store_import_settings(project)
        success(project)
      elsif project.errors[:import_source_disabled].present?
        error(project.errors[:import_source_disabled], :forbidden)
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
        **access_params
      ).execute(extra_project_attrs)
    end

    def repo
      @repo ||= client.repository(params[:repo_id].to_i)
    end

    def project_name
      @project_name ||= params[:new_name].presence || repo[:name]
    end

    def target_namespace
      @target_namespace ||= Namespace.find_by_full_path(target_namespace_path)
    end

    def extra_project_attrs
      {}
    end

    def url
      @url ||= params[:github_hostname]
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

    private

    def validate_access_token
      begin
        client.octokit.repository(params[:repo_id].to_i)
      rescue Octokit::Forbidden, Octokit::Unauthorized
        return error(repository_access_error_message, :unprocessable_entity)
      end

      return unless Gitlab::Utils.to_boolean(params.dig(:optional_stages, :collaborators_import))

      begin
        client.octokit.collaborators(params[:repo_id].to_i)
      rescue Octokit::Forbidden, Octokit::Unauthorized
        return error(collaborators_access_error_message, :unprocessable_entity)
      end
      nil # we intentionally return nil if we don't raise an error
    end

    def repository_access_error_message
      s_(
        "GithubImport|Your GitHub personal access token does not have read access to the repository. " \
          "Please use a classic GitHub personal access token with the `repo` scope. Fine-grained tokens " \
          "are not supported."
      )
    end

    def collaborators_access_error_message
      s_(
        "GithubImport|Your GitHub personal access token does not have read access to collaborators. " \
          "Please use a classic GitHub personal access token with the `read:org` scope. Fine-grained " \
          "tokens are not supported."
      )
    end

    def validate_context
      if blocked_url?
        log_and_return_error(
          "Invalid URL: #{url}",
          format(_("Invalid URL: %{url}"), { url: url }),
          :bad_request
        )
      elsif target_namespace.nil?
        error(s_('GithubImport|Namespace or group to import repository into does not exist.'), :unprocessable_entity)
      elsif !authorized?
        error(s_('GithubImport|You are not allowed to import projects in this namespace.'), :unprocessable_entity)
      end
    end

    def target_namespace_path
      raise ArgumentError, s_('GithubImport|Target namespace is required') if params[:target_namespace].blank?

      params[:target_namespace]
    end

    def log_error(exception)
      Gitlab::GithubImport::Logger.error(
        message: 'Import failed because of a GitHub error',
        status: exception.response_status,
        error: exception.response_body
      )

      error(
        format(
          s_('GithubImport|Import failed because of a GitHub error: %{original} (HTTP %{code})'),
          {
            original: exception.response_body,
            code: exception.response_status
          }
        ),
        :unprocessable_entity
      )
    end

    def log_and_return_error(message, translated_message, http_status)
      Gitlab::GithubImport::Logger.error(
        message: 'Error while attempting to import from GitHub',
        error: message
      )

      error(translated_message, http_status)
    end

    def store_import_settings(project)
      Gitlab::GithubImport::Settings
        .new(project)
        .write(
          timeout_strategy: params[:timeout_strategy] || ProjectImportData::PESSIMISTIC_TIMEOUT,
          optional_stages: params[:optional_stages],
          pagination_limit: params[:pagination_limit]
        )
    end
  end
end

Import::GithubService.prepend_mod_with('Import::GithubService')
