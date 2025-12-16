# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Prerequisite
        class ManagedResource < Base
          ManagedResourceError = Class.new(StandardError)

          DEFAULT_TEMPLATE_NAME = "default"

          BATCH_SIZE = 100

          def unmet?
            return false unless valid_for_managed_resources?(environment:, build:)
            return false unless managed_resources_enabled_in_environment_options?(build:)
            return false unless resource_management_enabled?

            !managed_resource&.completed?
          end

          def complete!
            return unless unmet?

            managed_resource = create_managed_resource

            response = ensure_environment
            if response.errors.any?
              managed_resource.update!(status: :failed)
              raise ManagedResourceError, format_error_message(response.errors)
            else
              managed_resource.assign_attributes(
                status: :completed,
                template_name: get_template.name,
                tracked_objects: tracked_objects(response.objects)
              )

              deletion_strategy = template_yaml['delete_resources']
              managed_resource.deletion_strategy = deletion_strategy if deletion_strategy.present?

              managed_resource.save!

              track_events(response)
            end
          end

          private

          def tracked_objects(objects)
            defaults = { group: "", namespace: "" }

            objects.map do |obj|
              defaults.merge(obj.to_h)
            end
          end

          def resource_management_enabled?
            return false unless environment.cluster_agent.resource_management_enabled?

            authorization = ::Clusters::Agents::Authorizations::CiAccess::Finder
                              .new(build.project, agent: environment.cluster_agent).execute.first

            authorization.present? && authorization.config.dig('resource_management', 'enabled') == true
          end

          def ensure_environment
            rendered_template = kas_client.render_environment_template(
              template: get_template,
              environment: environment,
              build: build)

            kas_client.ensure_environment(
              template: rendered_template,
              environment: environment,
              build: build)
          end

          def get_template
            get_custom_environment_template
          rescue GRPC::NotFound
            kas_client.get_default_environment_template
          end
          strong_memoize_attr :get_template

          def template_yaml
            YAML.safe_load(get_template.data)
          end
          strong_memoize_attr :template_yaml

          def get_custom_environment_template
            kas_client.get_environment_template(agent: environment.cluster_agent, template_name: DEFAULT_TEMPLATE_NAME)
          end

          def valid_for_managed_resources?(environment:, build:)
            environment&.cluster_agent && build.user
          end

          def managed_resources_enabled_in_environment_options?(build:)
            environment_options = build.options&.dig(:environment) || {}

            is_enabled = environment_options.dig(:kubernetes, :managed_resources, :enabled)
            is_enabled.nil? || is_enabled
          end

          def kas_client
            @kas_client ||= Gitlab::Kas::Client.new
          end

          def environment
            build.deployment&.environment
          end

          def managed_resource
            Clusters::Agents::ManagedResource.find_by_build_id(build.id)
          end
          strong_memoize_attr :managed_resource

          def create_managed_resource
            return managed_resource if managed_resource

            Clusters::Agents::ManagedResource.create!(
              build: build,
              project: build.project,
              environment: environment,
              cluster_agent: environment.cluster_agent)
          end

          def format_error_message(object_errors)
            "Failed to ensure the environment. #{object_errors.map(&:to_json).join(', ')}"
          end

          def track_events(response)
            Gitlab::InternalEvents.track_event(
              'ensure_environment_for_managed_resource',
              user: build.user,
              project: build.project,
              additional_properties: {
                label: build.project.namespace.actual_plan_name,
                property: environment.tier,
                value: environment.id
              }
            )

            response.objects.each_slice(BATCH_SIZE) do |objects|
              objects.each do |object|
                Gitlab::InternalEvents.track_event(
                  'ensure_gvk_resource_for_managed_resource',
                  user: build.user,
                  project: build.project,
                  additional_properties: {
                    label: "#{object.group}/#{object.version}/#{object.kind}",
                    property: environment.tier,
                    value: environment.id
                  }
                )
              end
            end
          end
        end
      end
    end
  end
end
