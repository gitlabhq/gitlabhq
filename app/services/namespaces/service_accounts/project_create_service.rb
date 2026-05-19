# frozen_string_literal: true

module Namespaces
  module ServiceAccounts
    class ProjectCreateService < BaseCreateService
      extend ::Gitlab::Utils::Override

      private

      override :resource
      def resource
        ::Project.find_by_id(params[:project_id])
      end
      strong_memoize_attr :resource

      override :resource_type
      def resource_type
        'project'
      end

      override :provisioning_params
      def provisioning_params
        { provisioned_by_project_id: resource.id }
      end
    end
  end
end
