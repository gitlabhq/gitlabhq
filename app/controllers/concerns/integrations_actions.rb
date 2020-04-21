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
    saved = integration.update(service_params[:service])

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
    render json: {}, status: :ok
  end

  private

  def integrations_enabled?
    false
  end

  def integration
    # Using instance variable `@service` still required as it's used in ServiceParams
    # and app/views/shared/_service_settings.html.haml. Should be removed once
    # those 2 are refactored to use `@integration`.
    @integration = @service ||= find_or_initialize_integration(params[:id]) # rubocop:disable Gitlab/ModuleWithInstanceVariables
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
end
