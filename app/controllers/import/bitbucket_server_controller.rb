# frozen_string_literal: true

class Import::BitbucketServerController < Import::BaseController
  before_action :verify_bitbucket_server_import_enabled
  before_action :bitbucket_auth, except: [:new, :configure]
  before_action :validate_import_params, only: [:create]

  # As a basic sanity check to prevent URL injection, restrict project
  # repository input and repository slugs to allowed characters. For Bitbucket:
  #
  # Project keys must start with a letter and may only consist of ASCII letters, numbers and underscores (A-Z, a-z, 0-9, _).
  #
  # Repository names are limited to 128 characters. They must start with a
  # letter or number and may contain spaces, hyphens, underscores, and periods.
  # (https://community.atlassian.com/t5/Answers-Developer-Questions/stash-repository-names/qaq-p/499054)
  VALID_BITBUCKET_CHARS = /\A[a-zA-z0-9\-_\.\s]+\z/

  def new
  end

  def create
    repo = bitbucket_client.repo(@project_key, @repo_slug)

    unless repo
      return render json: { errors: "Project #{@project_key}/#{@repo_slug} could not be found" }, status: :unprocessable_entity
    end

    project_name = params[:new_name].presence || repo.name
    namespace_path = params[:new_namespace].presence || current_user.username
    target_namespace = find_or_create_namespace(namespace_path, current_user)

    if current_user.can?(:create_projects, target_namespace)
      project = Gitlab::BitbucketServerImport::ProjectCreator.new(@project_key, @repo_slug, repo, project_name, target_namespace, current_user, credentials).execute

      if project.persisted?
        render json: ProjectSerializer.new.represent(project)
      else
        render json: { errors: project_save_error(project) }, status: :unprocessable_entity
      end
    else
      render json: { errors: 'This namespace has already been taken! Please choose another one.' }, status: :unprocessable_entity
    end
  rescue BitbucketServer::Client::ServerError => e
    render json: { errors: "Unable to connect to server: #{e}" }, status: :unprocessable_entity
  end

  def configure
    session[personal_access_token_key] = params[:personal_access_token]
    session[bitbucket_server_username_key] = params[:bitbucket_username]
    session[bitbucket_server_url_key] = params[:bitbucket_server_url]

    redirect_to status_import_bitbucket_server_path
  end

  def status
    repos = bitbucket_client.repos

    @repos, @incompatible_repos = repos.partition { |repo| repo.valid? }

    @already_added_projects = find_already_added_projects('bitbucket_server')
    already_added_projects_names = @already_added_projects.pluck(:import_source)

    @repos.to_a.reject! { |repo| already_added_projects_names.include?(repo.browse_url) }
  rescue BitbucketServer::Connection::ConnectionError, BitbucketServer::Client::ServerError => e
    flash[:alert] = "Unable to connect to server: #{e}"
    clear_session_data
    redirect_to new_import_bitbucket_server_path
  end

  def jobs
    render json: find_jobs('bitbucket_server')
  end

  private

  def bitbucket_client
    @bitbucket_client ||= BitbucketServer::Client.new(credentials)
  end

  def validate_import_params
    @project_key = params[:project]
    @repo_slug = params[:repository]

    return render_validation_error('Missing project key' ) unless @project_key.present? && @repo_slug.present?
    return render_validation_error('Missing repository slug') unless @repo_slug.present?
    return render_validation_error('Invalid project key') unless @project_key =~ VALID_BITBUCKET_CHARS
    return render_validation_error('Invalid repository slug') unless @repo_slug =~ VALID_BITBUCKET_CHARS
  end

  def render_validation_error(message)
    render json: { errors: message }, status: :unprocessable_entity
  end

  def bitbucket_auth
    unless session[bitbucket_server_url_key].present? &&
        session[bitbucket_server_username_key].present? &&
        session[personal_access_token_key].present?
      redirect_to new_import_bitbucket_server_path
    end
  end

  def verify_bitbucket_server_import_enabled
    render_404 unless bitbucket_server_import_enabled?
  end

  def bitbucket_server_url_key
    :bitbucket_server_url
  end

  def bitbucket_server_username_key
    :bitbucket_server_username
  end

  def personal_access_token_key
    :bitbucket_server_personal_access_token
  end

  def clear_session_data
    session[bitbucket_server_url_key] = nil
    session[bitbucket_server_username_key] = nil
    session[personal_access_token_key] = nil
  end

  def credentials
    {
      base_uri: session[bitbucket_server_url_key],
      user: session[bitbucket_server_username_key],
      password: session[personal_access_token_key]
    }
  end
end
