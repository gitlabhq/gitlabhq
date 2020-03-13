# frozen_string_literal: true

class Admin::IntegrationsController < Admin::ApplicationController
  include ServiceParams

  before_action :not_found, unless: :instance_level_integrations_enabled?
  before_action :service, only: [:edit, :update, :test]

  def edit
  end

  def update
    @service.attributes = service_params[:service]

    if @service.save(context: :manual_change)
      redirect_to edit_admin_application_settings_integration_path(@service), notice: success_message
    else
      render :edit
    end
  end

  def test
    if @service.can_test?
      render json: service_test_response, status: :ok
    else
      render json: {}, status: :not_found
    end
  end

  private

  def instance_level_integrations_enabled?
    Feature.enabled?(:instance_level_integrations)
  end

  def project
    # TODO: Change to something more meaningful
    Project.first
  end

  def service
    @service ||= project.find_or_initialize_service(params[:id])
  end

  def success_message
    message = @service.active? ? _('activated') : _('settings saved, but not activated')

    _('%{service_title} %{message}.') % { service_title: @service.title, message: message }
  end

  def service_test_response
    unless @service.update(service_params[:service])
      return { error: true, message: _('Validations failed.'), service_response: @service.errors.full_messages.join(','), test_failed: false }
    end

    data = @service.test_data(project, current_user)
    outcome = @service.test(data)

    unless outcome[:success]
      return { error: true, message: _('Test failed.'), service_response: outcome[:result].to_s, test_failed: true }
    end

    {}
  rescue Gitlab::HTTP::BlockedUrlError => e
    { error: true, message: _('Test failed.'), service_response: e.message, test_failed: true }
  end
end
