# frozen_string_literal: true

class Clusters::BaseController < ApplicationController
  include RoutableActions

  skip_before_action :authenticate_user!
  before_action :authorize_admin_cluster!, except: [:show, :index, :new, :authorize_aws_role, :update]

  helper_method :clusterable

  feature_category :deployment_management
  urgency :low, [
    :index, :show, :environments, :cluster_status, :prometheus_proxy,
    :destroy, :new_cluster_docs, :connect, :new, :create_user
  ]

  private

  def cluster
    @cluster ||= clusterable.clusters.find(params[:id])
                                 .present(current_user: current_user)
  end

  def authorize_update_cluster!
    access_denied! unless can?(current_user, :update_cluster, clusterable)
  end

  def authorize_admin_cluster!
    access_denied! unless can?(current_user, :admin_cluster, clusterable)
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
