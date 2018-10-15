# frozen_string_literal: true

class Clusters::BaseController < ApplicationController
  include RoutableActions

  skip_before_action :authenticate_user!
  before_action :require_project_id
  before_action :project, if: :project_type?
  before_action :repository, if: :project_type?
  before_action :authorize_read_cluster!

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

  def clusterable
    project if project_type?
  end

  def project_type?
    params[:project_id].present?
  end
end
