# frozen_string_literal: true

class Clusters::BaseController < ApplicationController
  include RoutableActions

  skip_before_action :authenticate_user!
  before_action :clusterable
  before_action :authorize_admin_cluster!, except: [:show, :index, :new, :authorize_aws_role, :update]

  helper_method :clusterable

  feature_category :deployment_management
  urgency :low, [
    :index, :show, :environments, :cluster_status,
    :destroy, :new_cluster_docs, :connect, :new, :create_user
  ]

  private

  def cluster
    @cluster ||= clusterable.clusters.find(params.permit(:id)[:id])
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

  # For Group/Clusters and Project/Clusters, the clusterable object (group or project)
  #   is fetched through `find_routable!`, which calls a `render_404` if the user does not have access to the object
  # The `clusterable` method will need to be in its own before_action call before the `authorize_*` calls
  #   so that the call stack will not proceed to the `authorize_*` calls
  #   and instead just render a not found page after the `clusterable` call
  def clusterable
    raise NotImplementedError
  end
end
