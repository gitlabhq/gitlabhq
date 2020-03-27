# frozen_string_literal: true

class Admin::ServicesController < Admin::ApplicationController
  include ServiceParams

  before_action :service, only: [:edit, :update]

  def index
    @services = Service.find_or_create_templates.sort_by(&:title)
  end

  def edit
    unless service.present?
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
end
