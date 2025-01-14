# frozen_string_literal: true
module API
  class Integrations < ::API::Base
    feature_category :integrations

    INTEGRATIONS_TAGS = %w[integrations].freeze

    integrations = Helpers::IntegrationsHelpers.integrations
    integration_classes = Helpers::IntegrationsHelpers.integration_classes

    if Gitlab.dev_or_test_env?
      integrations['mock-ci'] = ::Integrations::MockCi.api_arguments
      integrations['mock-monitoring'] = []

      integration_classes += Helpers::IntegrationsHelpers.development_integration_classes
    end

    INTEGRATIONS = integrations.freeze

    integration_classes.each do |integration|
      event_names = integration.try(:event_names) || next
      event_names.each do |event_name|
        INTEGRATIONS[integration.to_param.dasherize] << {
          required: false,
          name: event_name.to_sym,
          type: ::Grape::API::Boolean,
          desc: IntegrationsHelper.integration_event_description(integration, event_name)
        }
      end

      INTEGRATIONS[integration.to_param.dasherize] << Helpers::IntegrationsHelpers.inheritance_field
    end

    SLASH_COMMAND_INTEGRATIONS = {
      'mattermost-slash-commands' => ::Integrations::MattermostSlashCommands.api_arguments,
      'slack-slash-commands' => ::Integrations::SlackSlashCommands.api_arguments
    }.freeze

    helpers do
      def integration_attributes(integration)
        integration.fields.inject([]) do |arr, hash|
          arr << hash[:name].to_sym
        end
      end
    end

    # The API officially documents only the `:id/integrations` API paths.
    # We support the older `id:/services` path for backwards-compatibility in API V4.
    # The support for `:id/services` can be dropped if we create an API V5.
    [':id/services', ':id/integrations'].each do |path|
      params do
        requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
      end
      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        before { authenticate! }
        before { authorize_admin_integrations }

        desc 'List all active integrations' do
          detail 'Get a list of all active project integrations.'
          success Entities::ProjectIntegrationBasic
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
          is_array true
          tags INTEGRATIONS_TAGS
        end
        get path do
          integrations = user_project.integrations.active

          present integrations, with: Entities::ProjectIntegrationBasic
        end

        INTEGRATIONS.each do |slug, settings|
          desc "Create/Edit #{slug.titleize} integration" do
            detail "Set #{slug.titleize} integration for a project."
            success Entities::ProjectIntegrationBasic
            failure [
              { code: 400, message: 'Bad request' },
              { code: 401, message: 'Unauthorized' },
              { code: 404, message: 'Not found' },
              { code: 422, message: 'Unprocessable entity' }
            ]
            tags INTEGRATIONS_TAGS
          end
          params do
            settings.each do |setting|
              if setting[:required]
                requires setting[:name], type: setting[:type], desc: setting[:desc]
              else
                optional setting[:name], type: setting[:type], desc: setting[:desc]
              end
            end
          end
          put "#{path}/#{slug}" do
            integration = user_project.find_or_initialize_integration(slug.underscore)

            render_api_error!('400 Integration not available', 400) if integration.nil?

            params = declared_params(include_missing: false).merge(active: true)

            unless integration.manual_activation? || integration.is_a?(::Integrations::Prometheus)
              if integration.new_record?
                render_api_error!("You cannot create the #{integration.class.title} integration from the API", 422)
              end

              params.delete(:active)
            end

            result = ::Integrations::UpdateService.new(
              current_user: current_user, integration: integration, attributes: params
            ).execute

            if result.success?
              present integration, with: Entities::ProjectIntegration
            else
              render_api_error!(result.message, 400)
            end
          end
        end

        desc "Disable an integration" do
          detail "Disable the integration for a project. Integration settings are preserved."
          success code: 204
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
          tags INTEGRATIONS_TAGS
        end
        params do
          requires :slug, type: String, values: INTEGRATIONS.keys, desc: 'The name of the integration'
        end
        delete "#{path}/:slug" do
          integration = user_project.find_or_initialize_integration(params[:slug].underscore)

          not_found!('Integration') unless integration&.persisted?

          if integration.is_a?(::Integrations::JiraCloudApp)
            render_api_error!("You cannot disable the #{integration.class.title} integration from the API", 422)
          end

          destroy_conditionally!(integration) do
            attrs = integration_attributes(integration).index_with do |attr|
              column = if integration.attribute_present?(attr)
                         integration.column_for_attribute(attr)
                       elsif integration.data_fields_present?
                         integration.data_fields.column_for_attribute(attr)
                       end

              case column
              when nil, ActiveRecord::ConnectionAdapters::NullColumn
                nil
              else
                column.default
              end
            end.merge(active: false)

            render_api_error!('400 Bad Request', 400) unless integration.update(attrs)
          end
        end

        desc "Get an integration settings" do
          detail "Get the integration settings for a project."
          success Entities::ProjectIntegration
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
          tags INTEGRATIONS_TAGS
        end
        params do
          requires :slug, type: String, values: INTEGRATIONS.keys, desc: 'The name of the integration'
        end
        get "#{path}/:slug" do
          integration = user_project.find_or_initialize_integration(params[:slug].underscore)

          not_found!('Integration') unless integration&.persisted?

          present integration, with: Entities::ProjectIntegration
        end
      end

      SLASH_COMMAND_INTEGRATIONS.each do |integration_slug, settings|
        helpers do
          def slash_command_integration(project, integration_slug, params)
            project.integrations.active.find do |integration|
              integration.try(:token) == params[:token] && integration.to_param == integration_slug.underscore
            end
          end
        end

        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
        end
        resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
          desc "Trigger a slash command for #{integration_slug}" do
            detail 'Added in GitLab 8.13'
            failure [
              { code: 401, message: 'Unauthorized' },
              { code: 404, message: 'Not found' }
            ]
            tags INTEGRATIONS_TAGS
          end
          params do
            settings.each do |setting|
              requires setting[:name], type: setting[:type], desc: setting[:desc]
            end
          end
          post "#{path}/#{integration_slug.underscore}/trigger", urgency: :low do
            project = find_project(params[:id])

            # This is not accurate, but done to prevent leakage of the project names
            not_found!('Integration') unless project

            integration = slash_command_integration(project, integration_slug, params)
            result = integration.try(:trigger, params)

            if result
              status result[:status] || 200
              present result
            else
              not_found!('Integration')
            end
          end
        end
      end
    end

    desc "Trigger a global slack command" do
      detail 'Added in GitLab 9.4'
      failure [
        { code: 401, message: 'Unauthorized' }
      ]
    end
    params do
      requires :text, type: String, desc: 'Text of the slack command'
    end
    post 'slack/trigger' do
      if result = Gitlab::SlashCommands::GlobalSlackHandler.new(params).trigger
        status result[:status] || 200
        present result
      else
        not_found!
      end
    end
  end
end

# Added for JiHu
# https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118289#note_1379334692
API::Integrations.prepend_mod
