# frozen_string_literal: true

class Import::BitbucketServerController < Import::BaseController
  extend ::Gitlab::Utils::Override

  include ActionView::Helpers::SanitizeHelper
  include SafeFormatHelper

  before_action :verify_bitbucket_server_import_enabled
  before_action :bitbucket_auth, except: [:new, :configure]
  before_action :normalize_import_params, only: [:create]
  before_action :validate_import_params, only: [:create]

  rescue_from BitbucketServer::Connection::ConnectionError, with: :bitbucket_connection_error

  # As a basic sanity check to prevent URL injection, restrict project
  # repository input and repository slugs to allowed characters. For Bitbucket:
  #
  # Project keys must start with a letter and may only consist of ASCII letters,
  # numbers and underscores (A-Z, a-z, 0-9, _).
  #
  # Repository names are limited to 128 characters. They must start with a
  # letter or number and may contain spaces, hyphens, underscores, and periods.
  # (https://community.atlassian.com/t5/Answers-Developer-Questions/stash-repository-names/qaq-p/499054)
  #
  # Bitbucket Server starts personal project names with a tilde.
  VALID_BITBUCKET_PROJECT_CHARS = /\A~?[\w\-\.\s]+\z/
  VALID_BITBUCKET_CHARS = /\A[\w\-\.\s]+\z/

  def new; end

  def create
    repo = client.repo(@project_key, @repo_slug)

    unless repo
      return render json: {
        errors: safe_format(
          s_("Project %{project_repo} could not be found"),
          project_repo: "#{@project_key}/#{@repo_slug}"
        )
      }, status: :unprocessable_entity
    end

    result = Import::BitbucketServerService.new(
      client,
      current_user,
      params.merge({ organization_id: Current.organization_id })
    ).execute(credentials)

    if result[:status] == :success
      render json: ProjectSerializer.new.represent(result[:project], serializer: :import)
    else
      render json: { errors: result[:message] }, status: result[:http_status]
    end
  end

  def configure
    session[personal_access_token_key] = params[:personal_access_token]
    session[bitbucket_server_username_key] = params[:bitbucket_server_username]
    session[bitbucket_server_url_key] = params[:bitbucket_server_url]

    redirect_to status_import_bitbucket_server_path(namespace_id: params[:namespace_id])
  end

  # We need to re-expose controller's internal method 'status' as action.
  # rubocop:disable Lint/UselessMethodDefinition
  def status
    super
  end
  # rubocop:enable Lint/UselessMethodDefinition

  protected

  override :importable_repos
  def importable_repos
    bitbucket_repos.filter(&:valid?)
  end

  override :incompatible_repos
  def incompatible_repos
    bitbucket_repos.reject(&:valid?)
  end

  override :provider_name
  def provider_name
    :bitbucket_server
  end

  override :provider_url
  def provider_url
    session[bitbucket_server_url_key]
  end

  private

  def client
    @client ||= BitbucketServer::Client.new(credentials)
  end

  def bitbucket_repos
    @bitbucket_repos ||= client.repos(
      page_offset: page_offset,
      limit: limit_per_page,
      filter: sanitized_filter_param
    ).to_a
  end

  def normalize_import_params
    project_key, repo_slug = params[:repo_id].split('/')
    params[:bitbucket_server_project] = project_key
    params[:bitbucket_server_repo] = repo_slug
  end

  def validate_import_params
    @project_key = params[:bitbucket_server_project]
    @repo_slug = params[:bitbucket_server_repo]

    return render_validation_error('Missing project key') unless @project_key.present? && @repo_slug.present?
    return render_validation_error('Missing repository slug') unless @repo_slug.present?
    return render_validation_error('Invalid project key') unless VALID_BITBUCKET_PROJECT_CHARS.match?(@project_key)

    render_validation_error('Invalid repository slug') unless VALID_BITBUCKET_CHARS.match?(@repo_slug)
  end

  def render_validation_error(message)
    render json: { errors: message }, status: :unprocessable_entity
  end

  def bitbucket_auth
    unless session[bitbucket_server_url_key].present? &&
        session[bitbucket_server_username_key].present? &&
        session[personal_access_token_key].present?
      redirect_to new_import_bitbucket_server_path(namespace_id: params[:namespace_id])
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

  def page_offset
    [0, params[:page].to_i].max
  end

  def limit_per_page
    BitbucketServer::Paginator::PAGE_LENGTH
  end

  def bitbucket_connection_error(error)
    flash[:alert] = _("Unable to connect to server: %{error}") % { error: error }
    clear_session_data

    respond_to do |format|
      format.json do
        render json: {
          error: {
            message: _("Unable to connect to server: %{error}") % { error: error },
            redirect: new_import_bitbucket_server_path
          }
        }, status: :unprocessable_entity
      end
    end
  end
end
