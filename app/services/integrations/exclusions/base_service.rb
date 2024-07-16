# frozen_string_literal: true

module Integrations
  module Exclusions
    class BaseService
      include Gitlab::Utils::StrongMemoize

      def initialize(current_user:, integration_name:, projects: [], groups: [])
        @user = current_user
        @integration_name = integration_name
        @projects = projects
        @groups = groups
      end

      private

      attr_reader :user, :integration_name, :projects, :groups

      def validate
        return ServiceResponse.error(message: 'not authorized') unless allowed?
        return ServiceResponse.error(message: 'not instance specific') unless instance_specific_integration?

        ServiceResponse.success(payload: []) unless projects.present? || groups.present?
      end

      def allowed?
        user.can?(:admin_all_resources)
      end

      def instance_specific_integration?
        Integration.instance_specific_integration_names.include?(integration_name)
      end

      def instance_integration
        integration_model.for_instance.first
      end
      strong_memoize_attr :instance_integration

      def integration_model
        Integration.integration_name_to_model(integration_name)
      end
      strong_memoize_attr :integration_model

      def integration_type
        Integration.integration_name_to_type(integration_name)
      end
      strong_memoize_attr :integration_type
    end
  end
end
