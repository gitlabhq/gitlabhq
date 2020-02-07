# frozen_string_literal: true

class Admin::ServicesController < Admin::ApplicationController
  include ServiceParams

  before_action :whitelist_query_limiting, only: [:index]
  before_action :service, only: [:edit, :update]

  def index
    @services = instance_level_services
  end

  def edit
    unless service.present?
      redirect_to admin_application_settings_services_path,
        alert: "Service is unknown or it doesn't exist"
    end
  end

  def update
    if service.update(service_params[:service])
      PropagateInstanceLevelServiceWorker.perform_async(service.id) if service.active?

      redirect_to admin_application_settings_services_path,
        notice: 'Application settings saved successfully'
    else
      render :edit
    end
  end

  private

  # rubocop: disable CodeReuse/ActiveRecord
  def instance_level_services
    Service.available_services_names.map do |service_name|
      service = "#{service_name}_service".camelize.constantize
      service.where(instance: true).first_or_create
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def service
    @service ||= Service.where(id: params[:id], instance: true).first
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def whitelist_query_limiting
    Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-foss/issues/42430')
  end
end
