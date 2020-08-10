# frozen_string_literal: true

class Clusters::BaseController < ApplicationController
  include RoutableActions

  skip_before_action :authenticate_user!
  before_action :authorize_read_cluster!

  helper_method :clusterable

  private

  def cluster
    @cluster ||= clusterable.clusters.find(params[:id])
                                 .present(current_user: current_user)
  end

  def authorize_update_cluster!
    access_denied! unless can?(current_user, :update_cluster, cluster)
  end

  def authorize_admin_cluster!
    access_denied! unless can?(current_user, :admin_cluster, cluster)
  end

  def authorize_read_cluster!
    access_denied! unless can?(current_user, :read_cluster, clusterable)
  end

  def authorize_create_cluster!
    access_denied! unless can?(current_user, :create_cluster, clusterable)
  end

  def authorize_read_prometheus!
    access_denied! unless can?(current_user, :read_prometheus, clusterable)
  end

  def clusterable
    raise NotImplementedError
  end
end
