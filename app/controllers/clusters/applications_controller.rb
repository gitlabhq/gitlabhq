# frozen_string_literal: true

class Clusters::ApplicationsController < Clusters::BaseController
  before_action :cluster
  before_action :authorize_create_cluster!, only: [:create]
  before_action :authorize_update_cluster!, only: [:update]

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
    params.permit(:application, :hostname, :email)
  end
end
