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

    TRIGGER_SERVICES = {
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
        def service_attributes(service)
          service.fields.inject([]) do |arr, hash|
            arr << hash[:name].to_sym
          end
        end
      end

      desc 'Get all active project services' do
        success Entities::ProjectServiceBasic
      end
      get ":id/services" do
        services = user_project.integrations.active

        present services, with: Entities::ProjectServiceBasic
      end

      INTEGRATIONS.each do |slug, settings|
        desc "Set #{slug} service for project"
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
            present integration, with: Entities::ProjectService
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
          attrs = service_attributes(integration).index_with { nil }.merge(active: false)

          render_api_error!('400 Bad Request', 400) unless integration.update(attrs)
        end
      end

      desc 'Get the integration settings for a project' do
        success Entities::ProjectService
      end
      params do
        requires :slug, type: String, values: INTEGRATIONS.keys, desc: 'The name of the service'
      end
      get ":id/services/:slug" do
        integration = user_project.find_or_initialize_integration(params[:slug].underscore)

        not_found!('Service') unless integration&.persisted?

        present integration, with: Entities::ProjectService
      end
    end

    TRIGGER_SERVICES.each do |service_slug, settings|
      helpers do
        def slash_command_service(project, service_slug, params)
          project.integrations.active.find do |service|
            service.try(:token) == params[:token] && service.to_param == service_slug.underscore
          end
        end
      end

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc "Trigger a slash command for #{service_slug}" do
          detail 'Added in GitLab 8.13'
        end
        params do
          settings.each do |setting|
            requires setting[:name], type: setting[:type], desc: setting[:desc]
          end
        end
        post ":id/services/#{service_slug.underscore}/trigger" do
          project = find_project(params[:id])

          # This is not accurate, but done to prevent leakage of the project names
          not_found!('Service') unless project

          service = slash_command_service(project, service_slug, params)
          result = service.try(:trigger, params)

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
