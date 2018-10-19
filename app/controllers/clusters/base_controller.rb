# frozen_string_literal: true

class Clusters::BaseController < ApplicationController
  include RoutableActions

  skip_before_action :authenticate_user!
  before_action :require_project_id
  before_action :project, if: :project_type?
  before_action :repository, if: :project_type?
  before_action :authorize_read_cluster!

  layout :determine_layout

  helper_method :clusters_page_path, :cluster_page_path, :new_cluster_page_path

  private

  # We can extend to `#group_type?` in the future
  def require_project_id
    not_found unless project_type?
  end

  def project
    @project ||= find_routable!(Project, File.join(params[:namespace_id], params[:project_id]))
  end

  def repository
    @repository ||= project.repository
  end

  def authorize_read_cluster!
    access_denied! unless can?(current_user, :read_cluster, clusterable)
  end

  def authorize_create_cluster!
    access_denied! unless can?(current_user, :create_cluster, clusterable)
  end

  def determine_layout
    if project_type?
      'project'
    end
  end

  def clusterable
    if project_type?
      project
    end
  end

  def cluster_page_path(cluster)
    if project_type?
      project_cluster_path(project, cluster)
    end
  end

  def clusters_page_path
    if project_type?
      project_clusters_path(project)
    end
  end

  def new_cluster_page_path
    if project_type?
      new_project_cluster_path(project)
    end
  end

  def project_type?
    params[:project_id].present?
  end
end
