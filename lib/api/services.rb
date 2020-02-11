# frozen_string_literal: true
module API
  class Services < Grape::API
    services = Helpers::ServicesHelpers.services
    service_classes = Helpers::ServicesHelpers.service_classes

    if Rails.env.development?
      services['mock-ci'] = [
        {
          required: true,
          name: :mock_service_url,
          type: String,
          desc: 'URL to the mock service'
        }
      ]
      services['mock-deployment'] = []
      services['mock-monitoring'] = []

      service_classes += Helpers::ServicesHelpers.development_service_classes
    end

    SERVICES = services.freeze
    SERVICE_CLASSES = service_classes.freeze

    SERVICE_CLASSES.each do |service|
      event_names = service.try(:event_names) || next
      event_names.each do |event_name|
        SERVICES[service.to_param.tr("_", "-")] << {
          required: false,
          name: event_name.to_sym,
          type: String,
          desc: service.event_description(event_name)
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
        services = user_project.services.active

        present services, with: Entities::ProjectServiceBasic
      end

      SERVICES.each do |service_slug, settings|
        desc "Set #{service_slug} service for project"
        params do
          settings.each do |setting|
            if setting[:required]
              requires setting[:name], type: setting[:type], desc: setting[:desc]
            else
              optional setting[:name], type: setting[:type], desc: setting[:desc]
            end
          end
        end
        put ":id/services/#{service_slug}" do
          service = user_project.find_or_initialize_service(service_slug.underscore)
          service_params = declared_params(include_missing: false).merge(active: true)

          if service.update(service_params)
            present service, with: Entities::ProjectService
          else
            render_api_error!('400 Bad Request', 400)
          end
        end
      end

      desc "Delete a service for project"
      params do
        requires :service_slug, type: String, values: SERVICES.keys, desc: 'The name of the service'
      end
      delete ":id/services/:service_slug" do
        service = user_project.find_or_initialize_service(params[:service_slug].underscore)

        destroy_conditionally!(service) do
          attrs = service_attributes(service).inject({}) do |hash, key|
            hash.merge!(key => nil)
          end

          unless service.update(attrs.merge(active: false))
            render_api_error!('400 Bad Request', 400)
          end
        end
      end

      desc 'Get the service settings for project' do
        success Entities::ProjectService
      end
      params do
        requires :service_slug, type: String, values: SERVICES.keys, desc: 'The name of the service'
      end
      get ":id/services/:service_slug" do
        service = user_project.find_or_initialize_service(params[:service_slug].underscore)
        present service, with: Entities::ProjectService
      end
    end

    TRIGGER_SERVICES.each do |service_slug, settings|
      helpers do
        # rubocop: disable CodeReuse/ActiveRecord
        def slash_command_service(project, service_slug, params)
          project.services.active.where(template: false).find do |service|
            service.try(:token) == params[:token] && service.to_param == service_slug.underscore
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord
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

API::Services.prepend_if_ee('EE::API::Services')
