# frozen_string_literal: true

class Admin::ServicesController < Admin::ApplicationController
  include Integrations::Params

  before_action :integration, only: [:edit, :update]
  before_action :disable_query_limiting, only: [:index]

  feature_category :integrations

  def index
    @activated_services = Integration.for_template.active.sort_by(&:title)
    @existing_instance_types = Integration.for_instance.pluck(:type) # rubocop: disable CodeReuse/ActiveRecord
  end

  def edit
    if integration.nil? || Integration.instance_exists_for?(integration.type)
      redirect_to admin_application_settings_services_path,
        alert: "Service is unknown or it doesn't exist"
    end
  end

  def update
    if integration.update(integration_params[:integration])
      PropagateServiceTemplateWorker.perform_async(integration.id) if integration.active? # rubocop:disable CodeReuse/Worker

      redirect_to admin_application_settings_services_path,
        notice: 'Application settings saved successfully'
    else
      render :edit
    end
  end

  private

  # rubocop: disable CodeReuse/ActiveRecord
  def integration
    @integration ||= Integration.find_by(id: params[:id], template: true)
    @service ||= @integration # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/329759
  end
  alias_method :service, :integration
  # rubocop: enable CodeReuse/ActiveRecord

  def disable_query_limiting
    Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/220357')
  end
end
