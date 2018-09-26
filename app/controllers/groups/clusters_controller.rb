# frozen_string_literal: true

module Groups
  class ClustersController < Groups::ApplicationController
    before_action :cluster, except: [:index, :new, :create_gcp, :create_user]
    before_action :authorize_read_cluster!
    before_action :user_cluster, only: [:new]
    before_action :authorize_create_cluster!, only: [:new]

    STATUS_POLLING_INTERVAL = 10_000

    def index
      @clusters = []
    end

    def new
    end

    def create_user
      @user_cluster = ::Clusters::GroupCreateService
        .new(group, current_user,  create_user_cluster_params)
        .execute

      if @user_cluster.persisted?
        redirect_to group_cluster_path(group, @user_cluster)
      else
        render :new, locals: { active_tab: 'user' }
      end
    end

    def show
    end

    def status
      respond_to do |format|
        format.json do
          Gitlab::PollingInterval.set_header(response, interval: STATUS_POLLING_INTERVAL)

          render json: ClusterSerializer
            .new(group: @group, current_user: @current_user)
            .represent_status(@cluster)
        end
      end
    end

    def destroy
      if cluster.destroy
        flash[:notice] = _('Kubernetes cluster integration was successfully removed.')
        redirect_to group_clusters_path(group), status: :found
      else
        flash[:notice] = _('Kubernetes cluster integration was not removed.')
        render :show
      end
    end

    private

    def cluster
      @cluster ||= group.clusters.find(params[:id])
        .present(current_user: current_user)
    end

    def user_cluster
      @user_cluster = ::Clusters::Cluster.new.tap do |cluster|
        cluster.build_platform_kubernetes
      end
    end

    def create_user_cluster_params
      params.require(:cluster).permit(
        :enabled,
        :name,
        :environment_scope,
        platform_kubernetes_attributes: [
          :namespace,
          :api_url,
          :token,
          :ca_cert,
          :authorization_type
        ]).merge(
          provider_type: :user,
          platform_type: :kubernetes
        )
    end

    def authorize_read_cluster!
      unless can?(current_user, :read_cluster, group)
        access_denied!
      end
    end

    def authorize_create_cluster!
      unless can?(current_user, :create_cluster, group)
        access_denied!
      end
    end
  end
end
