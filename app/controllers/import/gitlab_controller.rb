class Import::GitlabController < Import::BaseController
  MAX_PROJECT_PAGES = 15
  PER_PAGE_PROJECTS = 100

  before_action :verify_gitlab_import_enabled
  before_action :gitlab_auth, except: :callback

  rescue_from OAuth2::Error, with: :gitlab_unauthorized

  def callback
    session[:gitlab_access_token] = client.get_token(params[:code], callback_import_gitlab_url)
    redirect_to status_import_gitlab_url
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def status
    @repos = client.projects(starting_page: 1, page_limit: MAX_PROJECT_PAGES, per_page: PER_PAGE_PROJECTS)

    @already_added_projects = find_already_added_projects('gitlab')
    already_added_projects_names = @already_added_projects.pluck(:import_source)

    @repos = @repos.to_a.reject { |repo| already_added_projects_names.include? repo["path_with_namespace"] }
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def jobs
    render json: find_jobs('gitlab')
  end

  def create
    repo = client.project(params[:repo_id].to_i)
    target_namespace = find_or_create_namespace(repo['namespace']['path'], client.user['username'])

    if current_user.can?(:create_projects, target_namespace)
      project = Gitlab::GitlabImport::ProjectCreator.new(repo, target_namespace, current_user, access_params).execute

      if project.persisted?
        render json: ProjectSerializer.new.represent(project)
      else
        render json: { errors: project_save_error(project) }, status: :unprocessable_entity
      end
    else
      render json: { errors: 'This namespace has already been taken! Please choose another one.' }, status: :unprocessable_entity
    end
  end

  private

  def client
    @client ||= Gitlab::GitlabImport::Client.new(session[:gitlab_access_token])
  end

  def verify_gitlab_import_enabled
    render_404 unless gitlab_import_enabled?
  end

  def gitlab_auth
    if session[:gitlab_access_token].blank?
      go_to_gitlab_for_permissions
    end
  end

  def go_to_gitlab_for_permissions
    redirect_to client.authorize_url(callback_import_gitlab_url)
  end

  def gitlab_unauthorized
    go_to_gitlab_for_permissions
  end

  def access_params
    { gitlab_access_token: session[:gitlab_access_token] }
  end
end
