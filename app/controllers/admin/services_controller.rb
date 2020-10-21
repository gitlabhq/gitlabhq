# frozen_string_literal: true

class Admin::ServicesController < Admin::ApplicationController
  include ServiceParams

  before_action :service, only: [:edit, :update]
  before_action :whitelist_query_limiting, only: [:index]

  feature_category :integrations

  def index
    @services = Service.find_or_create_templates.sort_by(&:title)
    @existing_instance_types = Service.for_instance.pluck(:type) # rubocop: disable CodeReuse/ActiveRecord
  end

  def edit
    if service.nil? || Service.instance_exists_for?(service.type)
      redirect_to admin_application_settings_services_path,
        alert: "Service is unknown or it doesn't exist"
    end
  end

  def update
    if service.update(service_params[:service])
      PropagateServiceTemplateWorker.perform_async(service.id) if service.active? # rubocop:disable CodeReuse/Worker

      redirect_to admin_application_settings_services_path,
        notice: 'Application settings saved successfully'
    else
      render :edit
    end
  end

  private

  # rubocop: disable CodeReuse/ActiveRecord
  def service
    @service ||= Service.find_by(id: params[:id], template: true)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def whitelist_query_limiting
    Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab/-/issues/220357')
  end
end
