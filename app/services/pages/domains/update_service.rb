# frozen_string_literal: true

module Pages
  module Domains
    class UpdateService < BaseService
      def execute(domain)
        return unless authorized?

        return false unless domain.update(params)

        publish_event(domain)

        true
      end

      private

      def authorized?
        current_user.can?(:update_pages, project)
      end

      def publish_event(domain)
        event = PagesDomainUpdatedEvent.new(
          data: {
            project_id: project.id,
            namespace_id: project.namespace_id,
            root_namespace_id: project.root_namespace.id,
            domain_id: domain.id,
            domain: domain.domain
          }
        )

        Gitlab::EventStore.publish(event)
      end
    end
  end
end
