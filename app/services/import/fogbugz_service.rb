# frozen_string_literal: true

module Import
  class FogbugzService < Import::BaseService
    attr_reader :client, :params, :current_user

    def execute(credentials)
      url = credentials[:uri]

      if blocked_url?(url)
        return log_and_return_error("Invalid URL: #{url}", _("Invalid URL: %{url}") % { url: url }, :bad_request)
      end

      unless authorized?
        return log_and_return_error(
          "You don't have permissions to import this project",
          _("You don't have permissions to import this project"),
          :unauthorized
        )
      end

      unless repo
        return log_and_return_error(
          "Project #{repo_id} could not be found",
          s_("Fogbugz|Project %{repo} could not be found") % { repo: repo_id },
          :unprocessable_entity)
      end

      project = create_project(credentials)

      if project.persisted?
        success(project)
      elsif project.errors[:import_source_disabled].present?
        error(project.errors[:import_source_disabled], :forbidden)
      else
        error(project_save_error(project), :unprocessable_entity)
      end
    rescue StandardError => e
      log_and_return_error(
        "Fogbugz import failed due to an error: #{e}",
        s_("Fogbugz|Fogbugz import failed due to an error: %{error}" % { error: e }),
        :bad_request)
    end

    private

    def create_project(credentials)
      Gitlab::FogbugzImport::ProjectCreator.new(
        repo,
        project_name,
        target_namespace,
        current_user,
        credentials,
        umap
      ).execute
    end

    def repo_id
      @repo_id ||= params[:repo_id]
    end

    def repo
      @repo ||= client.repo(repo_id)
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

    def umap
      @umap ||= params[:umap]
    end

    def allow_local_requests?
      Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
    end

    def blocked_url?(url)
      Gitlab::HTTP_V2::UrlBlocker.blocked_url?(
        url,
        allow_localhost: allow_local_requests?,
        allow_local_network: allow_local_requests?,
        schemes: %w[http https],
        deny_all_requests_except_allowed: Gitlab::CurrentSettings.deny_all_requests_except_allowed?,
        outbound_local_requests_allowlist: Gitlab::CurrentSettings.outbound_local_requests_whitelist # rubocop:disable Naming/InclusiveLanguage -- existing setting
      )
    end

    def log_and_return_error(message, translated_message, error_type)
      log_error(message)
      error(translated_message, error_type)
    end

    def log_error(message)
      ::Import::Framework::Logger.error(
        message: 'Import failed due to a Fogbugz error',
        error: message
      )
    end
  end
end
