# frozen_string_literal: true

module Integrations
  module Exclusions
    class BaseService
      def initialize(current_user:, integration_name:, projects:)
        @user = current_user
        @integration_name = integration_name
        @projects = projects
      end

      def execute
        return ServiceResponse.error(message: 'not authorized') unless allowed?
        return ServiceResponse.error(message: 'not instance specific') unless instance_specific_integration?

        yield
      end

      private

      attr_reader :user, :integration_name, :projects

      def allowed?
        user.can?(:admin_all_resources)
      end

      def instance_specific_integration?
        Integration::INSTANCE_SPECIFIC_INTEGRATION_NAMES.include?(integration_name)
      end
    end
  end
end
