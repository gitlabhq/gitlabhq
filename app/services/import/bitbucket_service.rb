# frozen_string_literal: true

# Imports a project from Bitbucket Cloud using
# username and app password (not OAuth)
module Import
  class BitbucketService < Import::BaseService
    attr_reader :current_user, :params

    # @param [User] current_user
    # @param [Hash] params
    # @option params [String] bitbucket_username - Bitbucket Cloud username
    # @option params [String] bitbucket_app_password - Bitbucket Cloud user app password
    def initialize(current_user, params)
      @current_user = current_user
      @params = params
    end

    # rubocop:disable Style/IfUnlessModifier -- line becomes too long
    def execute
      unless authorized?
        return log_and_return_error("You don't have permissions to import this project", :unauthorized)
      end

      unless bitbucket_user.present?
        return log_and_return_error('Unable to authorize with Bitbucket. Check your credentials', :unauthorized)
      end

      if bitbucket_repo.error
        return log_and_return_error(
          Kernel.format("Project %{repo_path} could not be found", repo_path: normalized_repo_path),
          :unprocessable_entity
        )
      end

      project = create_project

      track_access_level('bitbucket')

      if project.persisted?
        success(project)
      elsif project.errors[:import_source_disabled].present?
        error(project.errors[:import_source_disabled], :forbidden)
      else
        log_and_return_error(project_save_error(project), :unprocessable_entity)
      end
    rescue StandardError => e
      log_and_return_error("Import failed due to an error: #{e}", :bad_request)
    end
    # rubocop:enable Style/IfUnlessModifier

    private

    def client
      @client ||= Bitbucket::Client.new(credentials)
    end

    def credentials
      {
        username: params[:bitbucket_username],
        app_password: params[:bitbucket_app_password]
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

    def log_and_return_error(message, error_type)
      log_error(message)
      error(_(message), error_type)
    end

    def log_error(message)
      ::Import::Framework::Logger.error(
        message: 'BitBucket Cloud import failed',
        error: message
      )
    end
  end
end
