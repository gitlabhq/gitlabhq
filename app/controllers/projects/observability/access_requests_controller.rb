# frozen_string_literal: true

module Projects
  module Observability
    class AccessRequestsController < BaseController
      include ::Observability::AccessRequestActions

      private

      def observability_namespace
        project.namespace
      end

      def setup_redirect_path
        project_observability_setup_path(project)
      end

      def already_enabled_message
        s_('Observability|Observability is already enabled for this namespace')
      end

      def success_message
        s_(
          'Observability|Observability is enabled for your personal namespace. ' \
            'Start by instrumenting your projects below.'
        )
      end

      def build_access_request_service(namespace)
        ::Observability::AccessRequestService.new(namespace, current_user, project: project)
      end
    end
  end
end
