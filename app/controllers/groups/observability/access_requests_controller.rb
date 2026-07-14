# frozen_string_literal: true

module Groups
  module Observability
    class AccessRequestsController < BaseController
      include ::Observability::AccessRequestActions

      def new; end

      private

      def observability_namespace
        group
      end

      def setup_redirect_path
        group_observability_setup_path(group)
      end

      def already_enabled_message
        s_('Observability|Observability is already enabled for this group')
      end

      def success_message
        s_(
          'Observability|Observability is enabled for your group. ' \
            'Start by instrumenting your projects below.'
        )
      end

      def build_access_request_service(namespace)
        ::Observability::AccessRequestService.new(namespace, current_user)
      end
    end
  end
end
