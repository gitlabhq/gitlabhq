# frozen_string_literal: true

class Clusters::ApplicationsController < Clusters::BaseController
  before_action :cluster
  before_action :authorize_create_cluster!, only: [:create]

  def create
    Clusters::Applications::CreateService
      .new(@cluster, current_user, create_cluster_application_params)
      .execute(request)

    head :no_content
  rescue Clusters::Applications::CreateService::InvalidApplicationError
    render_404
  rescue StandardError
    head :bad_request
  end

  private

  def cluster
    @cluster ||= clusterable.clusters.find(params[:id]) || render_404
  end

  def create_cluster_application_params
    params.permit(:application, :hostname, :email)
  end
end
