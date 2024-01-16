# frozen_string_literal: true

module Import
  class GithubService < Import::BaseService
    include ActiveSupport::NumberHelper
    include Gitlab::Utils::StrongMemoize

    MINIMUM_IMPORT_SCOPE = %w[repo].freeze
    COLLAB_IMPORT_SCOPES = %w[admin:org read:org].freeze

    attr_accessor :client
    attr_reader :params, :current_user

    def execute(access_params, provider)
      context_error = validate_context
      return context_error if context_error

      scope_error = validate_scopes
      return scope_error if scope_error

      project = create_project(access_params, provider)
      track_access_level('github')

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

    def oversized?
      repository_size_limit > 0 && repo[:size] > repository_size_limit
    end

    def oversize_error_message
      _('"%{repository_name}" size (%{repository_size}) is larger than the limit of %{limit}.') % {
        repository_name: repo[:name],
        repository_size: number_to_human_size(repo[:size]),
        limit: number_to_human_size(repository_size_limit)
      }
    end

    def repository_size_limit
      strong_memoize :repository_size_limit do
        namespace_limit = target_namespace.repository_size_limit.to_i

        if namespace_limit > 0
          namespace_limit
        else
          Gitlab::CurrentSettings.repository_size_limit.to_i
        end
      end
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
        deny_all_requests_except_allowed: Gitlab::CurrentSettings.deny_all_requests_except_allowed?
      )
    end

    private

    def validate_scopes
      # We need to call `#repo` to ensure the `#last_response` from the client has the headers we need.
      repo
      scopes = client.octokit.last_response.headers["x-oauth-scopes"]
      scopes = scopes.split(',').map(&:strip)

      unless scopes.intersect?(MINIMUM_IMPORT_SCOPE + COLLAB_IMPORT_SCOPES)
        return log_and_return_error('Invalid Scope', _('Your GitHub access token does not have the correct scope to import.'), :unprocessable_entity)
      end

      collaborators_import = params.dig(:optional_stages, :collaborators_import)
      # A value for `collaborators_import` may not be included in POST params
      # and the default value is `true`
      return unless collaborators_import == true || collaborators_import.nil?

      return if scopes.intersect?(COLLAB_IMPORT_SCOPES)

      log_and_return_error('Invalid scope', _('Your GitHub access token does not have the correct scope to import collaborators.'), :unprocessable_entity)
    end

    def validate_context
      if blocked_url?
        log_and_return_error("Invalid URL: #{url}", _("Invalid URL: %{url}") % { url: url }, :bad_request)
      elsif target_namespace.nil?
        error(_('Namespace or group to import repository into does not exist.'), :unprocessable_entity)
      elsif !authorized?
        error(_('You are not allowed to import projects in this namespace.'), :unprocessable_entity)
      elsif oversized?
        error(oversize_error_message, :unprocessable_entity)
      end
    end

    def target_namespace_path
      raise ArgumentError, 'Target namespace is required' if params[:target_namespace].blank?

      params[:target_namespace]
    end

    def log_error(exception)
      Gitlab::GithubImport::Logger.error(
        message: 'Import failed due to a GitHub error',
        status: exception.response_status,
        error: exception.response_body
      )

      error(_('Import failed due to a GitHub error: %{original} (HTTP %{code})') % { original: exception.response_body, code: exception.response_status }, :unprocessable_entity)
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
          extended_events: Feature.enabled?(:github_import_extended_events, current_user)
        )
    end
  end
end

Import::GithubService.prepend_mod_with('Import::GithubService')
