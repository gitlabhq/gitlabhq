# frozen_string_literal: true

module IntegrationsActions
  extend ActiveSupport::Concern

  included do
    include Integrations::Params

    before_action :integration, only: [:edit, :update, :test]
  end

  def edit
    render 'shared/integrations/edit'
  end

  def update
    saved = integration.update(integration_params[:integration])

    respond_to do |format|
      format.html do
        if saved
          PropagateIntegrationWorker.perform_async(integration.id)
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

  def reset
    integration.destroy!

    flash[:notice] = s_('Integrations|This integration, and inheriting projects were reset.')

    render json: {}, status: :ok
  end

  private

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def integration
    @integration ||= find_or_initialize_non_project_specific_integration(params[:id])
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def success_message
    if integration.active?
      s_('Integrations|%{integration} settings saved and active.') % { integration: integration.title }
    else
      s_('Integrations|%{integration} settings saved, but not active.') % { integration: integration.title }
    end
  end

  def serialize_as_json
    integration
      .as_json(only: integration.json_fields)
      .merge(errors: integration.errors.as_json)
  end
end
