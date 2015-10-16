class Admin::ServicesController < Admin::ApplicationController
  before_action :service, only: [:edit, :update]

  def index
    @services = services_templates
  end

  def edit
    unless service.present?
      redirect_to admin_application_settings_services_path,
        alert: "Service is unknown or it doesn't exist"
    end
  end

  def update
    if service.update_attributes(application_services_params[:service])
      redirect_to admin_application_settings_services_path,
        notice: 'Application settings saved successfully'
    else
      render :edit
    end
  end

  private

  def services_templates
    templates = []

    Service.available_services_names.each do |service_name|
      service_template = service_name.concat("_service").camelize.constantize
      templates << service_template.where(template: true).first_or_create
    end

    templates
  end

  def service
    @service ||= Service.where(id: params[:id], template: true).first
  end

  def application_services_params
    application_services_params = params.permit(:id,
      service: Projects::ServicesController::ALLOWED_PARAMS)
    if application_services_params[:service].is_a?(Hash)
      Projects::ServicesController::FILTER_BLANK_PARAMS.each do |param|
        application_services_params[:service].delete(param) if application_services_params[:service][param].blank? 
      end
    end
    application_services_params
  end
end
