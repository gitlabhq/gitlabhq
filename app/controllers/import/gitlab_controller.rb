class Import::GitlabController < Import::BaseController
  before_action :verify_gitlab_import_enabled
  before_action :gitlab_auth, except: :callback

  rescue_from OAuth2::Error, with: :gitlab_unauthorized

  def callback
    session[:gitlab_access_token] = client.get_token(params[:code], callback_import_gitlab_url)
    redirect_to status_import_gitlab_url
  end

  def status
    @repos = client.projects

    @already_added_projects = current_user.created_projects.where(import_type: "gitlab")
    already_added_projects_names = @already_added_projects.pluck(:import_source)

    @repos = @repos.to_a.reject { |repo| already_added_projects_names.include? repo["path_with_namespace"] }
  end

  def jobs
    jobs = current_user.created_projects.where(import_type: "gitlab").to_json(only: [:id, :import_status])
    render json: jobs
  end

  def create
    repo = client.project(params[:repo_id].to_i)
    target_namespace = find_or_create_namespace(repo['namespace']['path'], client.user['username'])

    if current_user.can?(:create_projects, target_namespace)
      project = Gitlab::GitlabImport::ProjectCreator.new(repo, target_namespace, current_user, access_params).execute

      if project.persisted?
        render json: ProjectSerializer.new.represent(project)
      else
        render json: { errors: project.errors.full_messages }, status: :unprocessable_entity
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
