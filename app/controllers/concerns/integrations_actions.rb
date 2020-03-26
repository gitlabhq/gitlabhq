# frozen_string_literal: true

module IntegrationsActions
  extend ActiveSupport::Concern

  included do
    include ServiceParams

    before_action :not_found, unless: :integrations_enabled?
    before_action :integration, only: [:edit, :update, :test]
  end

  def edit
    render 'shared/integrations/edit'
  end

  def update
    integration.attributes = service_params[:service]

    saved = integration.save(context: :manual_change)

    respond_to do |format|
      format.html do
        if saved
          redirect_to scoped_edit_integration_path(integration), notice: success_message
        else
          render 'shared/integrations/edit'
        end
      end

      format.json do
        status = saved ? :ok : :unprocessable_entity

        render json: serialize_as_json, status: status
      end
    end
  end

  def test
    if integration.can_test?
      render json: service_test_response, status: :ok
    else
      render json: {}, status: :not_found
    end
  end

  private

  def integrations_enabled?
    false
  end

  # TODO: Use actual integrations on the group / instance level
  # To be completed in https://gitlab.com/groups/gitlab-org/-/epics/2430
  def project
    Project.first
  end

  def integration
    # Using instance variable `@service` still required as it's used in ServiceParams
    # and app/views/shared/_service_settings.html.haml. Should be removed once
    # those 2 are refactored to use `@integration`.
    @integration = @service ||= project.find_or_initialize_service(params[:id]) # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end

  def success_message
    message = integration.active? ? _('activated') : _('settings saved, but not activated')

    _('%{service_title} %{message}.') % { service_title: integration.title, message: message }
  end

  def serialize_as_json
    integration
      .as_json(only: integration.json_fields)
      .merge(errors: integration.errors.as_json)
  end

  def service_test_response
    unless integration.update(service_params[:service])
      return { error: true, message: _('Validations failed.'), service_response: integration.errors.full_messages.join(','), test_failed: false }
    end

    data = integration.test_data(project, current_user)
    outcome = integration.test(data)

    unless outcome[:success]
      return { error: true, message: _('Test failed.'), service_response: outcome[:result].to_s, test_failed: true }
    end

    {}
  rescue Gitlab::HTTP::BlockedUrlError => e
    { error: true, message: _('Test failed.'), service_response: e.message, test_failed: true }
  end
end
