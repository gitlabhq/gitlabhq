class Import::GitlabController < ApplicationController
  before_filter :gitlab_auth, except: :callback

  rescue_from OAuth2::Error, with: :gitlab_unauthorized

  def callback
    token = client.get_token(params[:code], callback_import_gitlab_url)
    current_user.gitlab_access_token = token
    current_user.save
    redirect_to status_import_gitlab_url
  end

  def status
    @repos = client.projects
    
    @already_added_projects = current_user.created_projects.where(import_type: "gitlab")
    already_added_projects_names = @already_added_projects.pluck(:import_source)

    @repos.to_a.reject!{ |repo| already_added_projects_names.include? repo["path_with_namespace"] }
  end

  def jobs
    jobs = current_user.created_projects.where(import_type: "gitlab").to_json(only: [:id, :import_status])
    render json: jobs
  end

  def create
    @repo_id = params[:repo_id].to_i
    repo = client.project(@repo_id)
    target_namespace = params[:new_namespace].presence || repo["namespace"]["path"]
    existing_namespace = Namespace.find_by("path = ? OR name = ?", target_namespace, target_namespace)
    
    if existing_namespace
      if existing_namespace.owner == current_user
        namespace = existing_namespace
      else
        @already_been_taken = true
        @target_namespace = target_namespace
        @project_name = repo["path"]
        render and return
      end
    else
      namespace = Group.create(name: target_namespace, path: target_namespace, owner: current_user)
      namespace.add_owner(current_user)
    end

    @project = Gitlab::GitlabImport::ProjectCreator.new(repo, namespace, current_user).execute
  end

  private

  def client
    @client ||= Gitlab::GitlabImport::Client.new(current_user.gitlab_access_token)
  end

  def gitlab_auth
    if current_user.gitlab_access_token.blank?
      go_to_gitlab_for_permissions
    end
  end

  def go_to_gitlab_for_permissions
    redirect_to client.authorize_url(callback_import_gitlab_url)
  end

  def gitlab_unauthorized
    go_to_gitlab_for_permissions
  end
end
