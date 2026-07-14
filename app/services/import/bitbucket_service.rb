# frozen_string_literal: true

# Imports a project from Bitbucket Cloud using an API token
module Import
  class BitbucketService < Import::BaseService
    attr_reader :current_user, :params

    # @param [User] current_user
    # @param [Hash] params
    # @option params [String] bitbucket_email - Bitbucket Cloud email
    # @option params [String] bitbucket_api_token - Bitbucket Cloud API token
    def initialize(current_user, params)
      @current_user = current_user
      @params = params
    end

    def execute
      unless authorized?
        return log_and_return_error("You don't have permissions to import this project",
          _("You don't have permissions to import this project"), :unauthorized)
      end

      unless bitbucket_user.present?
        return log_and_return_error('Unable to authorize with Bitbucket. Check your credentials',
          _('Unable to authorize with Bitbucket. Check your credentials'), :unauthorized)
      end

      if bitbucket_repo.error
        return log_and_return_error(
          Kernel.format("Project %{repo_path} could not be found", repo_path: normalized_repo_path),
          format(_("Project %{repo_path} could not be found"), repo_path: normalized_repo_path),
          :unprocessable_entity
        )
      end

      project = create_project

      unless project
        return log_and_return_error(
          Kernel.format("Project %{repo_path} could not be found or is invalid", repo_path: normalized_repo_path),
          format(_("Project %{repo_path} could not be found or is invalid"), repo_path: normalized_repo_path),
          :unprocessable_entity
        )
      end

      track_access_level('bitbucket')

      if project.persisted?
        success(project)
      elsif project.errors[:import_source_disabled].present?
        error(project.errors[:import_source_disabled], :forbidden)
      else
        save_error = project_save_error(project)
        log_and_return_error(save_error, save_error, :unprocessable_entity)
      end
    rescue StandardError => e
      log_and_return_error("Import failed due to an error: #{e}", _("Import failed due to an error"), :bad_request)
    end

    private

    def client
      @client ||= Bitbucket::Client.new(credentials.merge(client_options), http_client: Import::Clients::HTTP)
    end

    def credentials
      {
        email: params[:bitbucket_email],
        api_token: params[:bitbucket_api_token]
      }
    end

    def client_options
      {
        logger: ::Import::Framework::Logger
      }
    end

    def create_project
      Gitlab::BitbucketImport::ProjectCreator.new(
        bitbucket_repo,
        project_name,
        target_namespace,
        current_user,
        credentials
      ).execute
    end

    def bitbucket_repo
      @bitbucket_repo ||= client.repo(normalized_repo_path)
    end

    def bitbucket_user
      @bitbucket_user = client.user
    end

    def normalized_repo_path
      @normalized_repo_path ||= params[:repo_path].to_s.gsub('___', '/')
    end

    def project_name
      @project_name ||= params[:new_name].presence || bitbucket_repo.name
    end

    def target_namespace
      @target_namespace ||= find_or_create_namespace(params[:target_namespace], current_user.namespace_path)
    end

    def log_and_return_error(message, translated_message, error_type)
      log_error(message)
      error(translated_message, error_type)
    end

    def log_error(message)
      ::Import::Framework::Logger.error(
        message: 'BitBucket Cloud import failed',
        error: message
      )
    end
  end
end
