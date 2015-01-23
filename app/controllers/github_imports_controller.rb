class GithubImportsController < ApplicationController
  before_filter :github_auth, except: :callback

  rescue_from Octokit::Unauthorized, with: :github_unauthorized

  def callback
    token = client.auth_code.get_token(params[:code]).token
    current_user.github_access_token = token
    current_user.save
    redirect_to status_github_import_url
  end

  def status
    @repos = octo_client.repos
    octo_client.orgs.each do |org|
      @repos += octo_client.repos(org.login)
    end

    @already_added_projects = current_user.created_projects.where(import_type: "github")
    already_added_projects_names = @already_added_projects.pluck(:import_source)

    @repos.reject!{|repo| already_added_projects_names.include? repo.full_name}
  end

  def jobs
    jobs = current_user.created_projects.where(import_type: "github").to_json(:only => [:id, :import_status])
    render json: jobs
  end

  def create
    @repo_id = params[:repo_id].to_i
    repo = octo_client.repo(@repo_id)
    target_namespace = params[:new_namespace].presence || repo.owner.login
    existing_namespace = Namespace.find_by("path = ? OR name = ?", target_namespace, target_namespace)

    if existing_namespace
      if existing_namespace.owner == current_user
        namespace = existing_namespace
      else
        @already_been_taken = true
        @target_namespace = target_namespace
        @project_name = repo.name
        render and return
      end
    else
      namespace = Group.create(name: target_namespace, path: target_namespace, owner: current_user)
      namespace.add_owner(current_user)
    end

    @project = Gitlab::Github::ProjectCreator.new(repo, namespace, current_user).execute
  end

  private

  def client
    @client ||= Gitlab::Github::Client.new.client
  end

  def octo_client
    Octokit.auto_paginate = true
    @octo_client ||= Octokit::Client.new(:access_token => current_user.github_access_token)
  end

  def github_auth
    if current_user.github_access_token.blank?
      go_to_github_for_permissions
    end
  end

  def go_to_github_for_permissions
    redirect_to client.auth_code.authorize_url({
      redirect_uri: callback_github_import_url,
      scope: "repo, user, user:email"
    })
  end

  def github_unauthorized
    go_to_github_for_permissions
  end
end
