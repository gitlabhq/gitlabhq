# frozen_string_literal: true

module API
  class Integrations
    class IntegratableOperations < Grape::API # rubocop:disable API/Base -- subclassing from Grape::API is required for mounting in the main API.
      INTEGRATIONS_TAGS = %w[integrations].freeze

      before do
        render_api_error!('400 Integration not available', 400) if disallowed_integration_at_group_level?(params[:slug])
      end

      mounted do
        helpers do
          def disallowed_integration_at_group_level?(slug)
            return unless slug.present?

            parent_resource.is_a?(Group) && Integration.project_specific_integration_names.include?(slug.underscore)
          end

          def integration_attributes(integration)
            integration.fields.inject([]) do |arr, hash|
              arr << hash[:name].to_sym
            end
          end

          def find_or_initialize_integration(slug)
            parent_resource.find_or_initialize_integration(slug.underscore)
          end

          def parent_resource
            unless respond_to?(:fetch_parent_resource, true)
              raise NotImplementedError,
                "You must implement a `fetch_parent_resource` method that returns " \
                  "the integratable resource in the namespace that mounts this API."
            end

            @parent_resource ||= fetch_parent_resource
          end
        end

        desc 'List all active integrations' do
          detail "Get a list of all active integrations."
          success Entities::IntegrationBasic
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
          is_array true
          tags INTEGRATIONS_TAGS
        end

        get(configuration[:path]) do
          integrations = parent_resource.integrations.active

          present integrations, with: Entities::IntegrationBasic
        end

        INTEGRATIONS.each do |slug, settings|
          desc "Create/Edit #{slug.titleize} integration" do
            detail "Set #{slug.titleize} integration."
            success Entities::IntegrationBasic
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
          put("#{configuration[:path]}/#{slug}") do
            integration = find_or_initialize_integration(slug)

            params = declared_params(include_missing: false).merge(active: true)

            render_api_error!('400 Integration not available', 400) if integration.nil?

            manual_or_special = integration.manual_activation?

            unless manual_or_special
              if integration.new_record?
                render_api_error!("You cannot create the #{integration.class.title} integration from the API", 422)
              end

              params.delete(:active)
            end

            result = ::Integrations::UpdateService.new(
              current_user: current_user, integration: integration, attributes: params
            ).execute

            if result.success?
              present integration, with: Entities::Integration
            else
              message = result.message || '400 Bad Request'
              render_api_error!(message, 400)
            end
          end
        end

        desc "Disable an integration" do
          detail "Disable the integration. Integration settings are preserved."
          success code: 204
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
          tags INTEGRATIONS_TAGS
        end
        params do
          requires :slug, type: String, values: INTEGRATIONS.keys,
            desc: 'The name of the integration'
        end
        delete("#{configuration[:path]}/:slug") do
          integration = find_or_initialize_integration(params[:slug])

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
          detail "Get the integration settings."
          success Entities::Integration
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
          tags INTEGRATIONS_TAGS
        end
        params do
          requires :slug, type: String, values: INTEGRATIONS.keys,
            desc: 'The name of the integration'
        end
        get("#{configuration[:path]}/:slug") do
          integration = find_or_initialize_integration(params[:slug])

          not_found!('Integration') unless integration&.persisted?

          present integration, with: Entities::Integration
        end
      end
    end
  end
end
