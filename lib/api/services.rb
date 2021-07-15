# frozen_string_literal: true
module API
  class Services < ::API::Base
    feature_category :integrations

    integrations = Helpers::IntegrationsHelpers.integrations
    integration_classes = Helpers::IntegrationsHelpers.integration_classes

    if Rails.env.development?
      integrations['mock-ci'] = [
        {
          required: true,
          name: :mock_service_url,
          type: String,
          desc: 'URL to the mock service'
        }
      ]
      integrations['mock-deployment'] = []
      integrations['mock-monitoring'] = []

      integration_classes += Helpers::IntegrationsHelpers.development_integration_classes
    end

    INTEGRATIONS = integrations.freeze

    integration_classes.each do |integration|
      event_names = integration.try(:event_names) || next
      event_names.each do |event_name|
        INTEGRATIONS[integration.to_param.tr("_", "-")] << {
          required: false,
          name: event_name.to_sym,
          type: String,
          desc: IntegrationsHelper.integration_event_description(integration, event_name)
        }
      end
    end

    TRIGGER_INTEGRATIONS = {
      'mattermost-slash-commands' => [
        {
          name: :token,
          type: String,
          desc: 'The Mattermost token'
        }
      ],
      'slack-slash-commands' => [
        {
          name: :token,
          type: String,
          desc: 'The Slack token'
        }
      ]
    }.freeze

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      before { authenticate! }
      before { authorize_admin_project }

      helpers do
        def integration_attributes(integration)
          integration.fields.inject([]) do |arr, hash|
            arr << hash[:name].to_sym
          end
        end
      end

      desc 'Get all active project integrations' do
        success Entities::ProjectIntegrationBasic
      end
      get ":id/services" do
        integrations = user_project.integrations.active

        present integrations, with: Entities::ProjectIntegrationBasic
      end

      INTEGRATIONS.each do |slug, settings|
        desc "Set #{slug} integration for project"
        params do
          settings.each do |setting|
            if setting[:required]
              requires setting[:name], type: setting[:type], desc: setting[:desc]
            else
              optional setting[:name], type: setting[:type], desc: setting[:desc]
            end
          end
        end
        put ":id/services/#{slug}" do
          integration = user_project.find_or_initialize_integration(slug.underscore)
          params = declared_params(include_missing: false).merge(active: true)

          if integration.update(params)
            present integration, with: Entities::ProjectIntegration
          else
            render_api_error!('400 Bad Request', 400)
          end
        end
      end

      desc "Delete an integration from a project"
      params do
        requires :slug, type: String, values: INTEGRATIONS.keys, desc: 'The name of the service'
      end
      delete ":id/services/:slug" do
        integration = user_project.find_or_initialize_integration(params[:slug].underscore)

        destroy_conditionally!(integration) do
          attrs = integration_attributes(integration).index_with { nil }.merge(active: false)

          render_api_error!('400 Bad Request', 400) unless integration.update(attrs)
        end
      end

      desc 'Get the integration settings for a project' do
        success Entities::ProjectIntegration
      end
      params do
        requires :slug, type: String, values: INTEGRATIONS.keys, desc: 'The name of the service'
      end
      get ":id/services/:slug" do
        integration = user_project.find_or_initialize_integration(params[:slug].underscore)

        not_found!('Service') unless integration&.persisted?

        present integration, with: Entities::ProjectIntegration
      end
    end

    TRIGGER_INTEGRATIONS.each do |integration_slug, settings|
      helpers do
        def slash_command_integration(project, integration_slug, params)
          project.integrations.active.find do |integration|
            integration.try(:token) == params[:token] && integration.to_param == integration_slug.underscore
          end
        end
      end

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc "Trigger a slash command for #{integration_slug}" do
          detail 'Added in GitLab 8.13'
        end
        params do
          settings.each do |setting|
            requires setting[:name], type: setting[:type], desc: setting[:desc]
          end
        end
        post ":id/services/#{integration_slug.underscore}/trigger" do
          project = find_project(params[:id])

          # This is not accurate, but done to prevent leakage of the project names
          not_found!('Service') unless project

          integration = slash_command_integration(project, integration_slug, params)
          result = integration.try(:trigger, params)

          if result
            status result[:status] || 200
            present result
          else
            not_found!('Service')
          end
        end
      end
    end
  end
end

API::Services.prepend_mod_with('API::Services')
