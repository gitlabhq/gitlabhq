# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        class Kubernetes < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable
          include ::Gitlab::Config::Entry::Attributable
          include ::Gitlab::Config::Entry::Configurable

          ALLOWED_KEYS = %i[namespace agent flux_resource_path managed_resources dashboard].freeze

          attributes ALLOWED_KEYS

          validations do
            validates :config, type: Hash, presence: true
            validates :config, allowed_keys: ALLOWED_KEYS

            # Deprecated. Use `dashboard.namespace` instead.
            validates :namespace, type: String, allow_nil: true
            validates :namespace, presence: true, if: -> { flux_resource_path.present? }

            validates :agent, type: String, allow_nil: true
            validates :agent, presence: true, if: -> { agent_required? }

            # Deprecated. Use `dashboard.flux_resource_path` instead.
            validates :flux_resource_path, type: String, allow_nil: true

            validates :managed_resources, json_schema: {
              base_directory: "lib/gitlab/ci/config/entry/schemas/kubernetes",
              detail_errors: true,
              filename: "managed_resources",
              hash_conversion: true,
              size_limit: 64.kilobytes
            }, allow_nil: true

            validates :dashboard, json_schema: {
              base_directory: "lib/gitlab/ci/config/entry/schemas/kubernetes",
              detail_errors: true,
              filename: "dashboard",
              hash_conversion: true,
              size_limit: 64.kilobytes
            }, if: -> { dashboard.present? }

            validate do
              if namespace.present? && dashboard.is_a?(Hash) && dashboard[:namespace].present?
                errors.add(:namespace, 'cannot be specified when dashboard.namespace is set')
              end

              if flux_resource_path.present? && dashboard.is_a?(Hash) && dashboard[:flux_resource_path].present?
                errors.add(:flux_resource_path, 'cannot be specified when dashboard.flux_resource_path is set')
              end
            end
          end

          def agent_required?
            flux_resource_path.present? ||
              dashboard.present? ||
              managed_resources_enabled?
          end

          def dashboard
            return {} unless @config.is_a?(Hash)

            @config[:dashboard] || {}
          end

          def managed_resources_enabled?
            return false unless @config.is_a?(Hash) && @config[:managed_resources].is_a?(Hash)

            @config.dig(:managed_resources, :enabled) == true
          end
        end
      end
    end
  end
end
