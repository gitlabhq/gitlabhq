class Import::BitbucketServerController < Import::BaseController
  before_action :verify_bitbucket_server_import_enabled
  before_action :bitbucket_auth, except: [:new, :configure]

  def new
  end

  def create
    bitbucket_client = BitbucketServer::Client.new(credentials)

    repo_id = params[:repo_id].to_s
    # XXX must be a better way
    project_slug, repo_slug = repo_id.split("___")
    repo = bitbucket_client.repo(project_slug, repo_slug)
    project_name = params[:new_name].presence || repo.name

    repo_owner = current_user.username
    namespace_path = params[:new_namespace].presence || repo_owner
    target_namespace = find_or_create_namespace(namespace_path, current_user)

    if current_user.can?(:create_projects, target_namespace)
      project = Gitlab::BitbucketServerImport::ProjectCreator.new(project_slug, repo_slug, repo, project_name, target_namespace, current_user, credentials).execute

      if project.persisted?
        render json: ProjectSerializer.new.represent(project)
      else
        render json: { errors: project_save_error(project) }, status: :unprocessable_entity
      end
    else
      render json: { errors: 'This namespace has already been taken! Please choose another one.' }, status: :unprocessable_entity
    end
  end

  def configure
    session[personal_access_token_key] = params[:personal_access_token]
    session[bitbucket_server_username_key] = params[:bitbucket_username]
    session[bitbucket_server_url_key] = params[:bitbucket_server_url]

    redirect_to status_import_bitbucket_server_path
  end

  def status
    bitbucket_client = BitbucketServer::Client.new(credentials)
    repos = bitbucket_client.repos

    @repos, @incompatible_repos = repos.partition { |repo| repo.valid? }

    @already_added_projects = find_already_added_projects('bitbucket_server')
    already_added_projects_names = @already_added_projects.pluck(:import_source)

    @repos.to_a.reject! { |repo| already_added_projects_names.include?(repo.full_name) }
  end

  def jobs
    render json: find_jobs('bitbucket_server')
  end

  private

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

  def credentials
    {
      base_uri: session[bitbucket_server_url_key],
      user: session[bitbucket_server_username_key],
      password: session[personal_access_token_key]
    }
  end
end
