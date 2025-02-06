# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Prerequisite
        class ManagedResource < Base
          ManagedResourceError = Class.new(StandardError)

          DEFAULT_TEMPLATE_NAME = "default"

          def unmet?
            return false unless resource_management_enabled?

            return false unless valid_for_managed_resources?(environment:, build:)

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
              managed_resource.update!(status: :completed)
            end
          end

          private

          # TODO: Check "resource_management.enabled" flag in the follow-up MR.
          def resource_management_enabled?
            false
          end

          def ensure_environment
            template = begin
              kas_client.get_environment_template(environment: environment, template_name: DEFAULT_TEMPLATE_NAME)
            rescue GRPC::NotFound
              kas_client.get_default_environment_template
            end

            rendered_template = kas_client.render_environment_template(
              template: template,
              environment: environment,
              build: build)

            kas_client.ensure_environment(
              template: rendered_template,
              environment: environment,
              build: build)
          end

          def valid_for_managed_resources?(environment:, build:)
            environment&.cluster_agent && build.user
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
        end
      end
    end
  end
end
