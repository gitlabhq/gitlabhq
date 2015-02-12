class Admin::ServicesController < Admin::ApplicationController
  before_filter :service, only: [:edit, :update]

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

    allowed_templates.each do |service|
      service_template = service.constantize
      templates << service_template.where(template: true).first_or_create
    end

    templates
  end

  def allowed_templates
    %w( JiraService RedmineService CustomIssueTrackerService )
  end

  def service
    @service ||= Service.where(id: params[:id], template: true).first
  end

  def application_services_params
    params.permit(:id,
      service: [
        :title, :project_url, :description, :issues_url, :new_issue_url
    ])
  end
end
