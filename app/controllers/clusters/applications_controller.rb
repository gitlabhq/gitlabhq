# frozen_string_literal: true

class Clusters::ApplicationsController < Clusters::BaseController
  before_action :cluster
  before_action :authorize_create_cluster!, only: [:create]
  before_action :authorize_update_cluster!, only: [:update]
  before_action :authorize_admin_cluster!, only: [:destroy]

  def create
    request_handler do
      Clusters::Applications::CreateService
        .new(@cluster, current_user, cluster_application_params)
        .execute(request)
    end
  end

  def update
    request_handler do
      Clusters::Applications::UpdateService
        .new(@cluster, current_user, cluster_application_params)
        .execute(request)
    end
  end

  def destroy
    request_handler do
      Clusters::Applications::DestroyService
        .new(@cluster, current_user, cluster_application_destroy_params)
        .execute(request)
    end
  end

  private

  def request_handler
    yield

    head :no_content
  rescue Clusters::Applications::BaseService::InvalidApplicationError
    render_404
  rescue StandardError
    head :bad_request
  end

  def cluster
    @cluster ||= clusterable.clusters.find(params[:id]) || render_404
  end

  def cluster_application_params
    params.permit(:application, :hostname, :pages_domain_id, :email, :stack, :host, :port, :protocol)
  end

  def cluster_application_destroy_params
    params.permit(:application)
  end
end
