class Admin::ServicesController < Admin::ApplicationController
  include ServiceParams

  before_action :whitelist_query_limiting, only: [:index]
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
    if service.update_attributes(service_params[:service])
      PropagateServiceTemplateWorker.perform_async(service.id) if service.active?

      redirect_to admin_application_settings_services_path,
        notice: 'Application settings saved successfully'
    else
      render :edit
    end
  end

  private

  def services_templates
    Service.available_services_names.map do |service_name|
      service_template = service_name.concat("_service").camelize.constantize
      service_template.where(template: true).first_or_create
    end
  end

  def service
    @service ||= Service.where(id: params[:id], template: true).first
  end

  def whitelist_query_limiting
    Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-ce/issues/42430')
  end
end
