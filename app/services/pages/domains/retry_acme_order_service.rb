# frozen_string_literal: true

module Pages
  module Domains
    class RetryAcmeOrderService
      attr_reader :pages_domain

      def initialize(pages_domain)
        @pages_domain = pages_domain
      end

      def execute
        updated = pages_domain.with_lock do
          next unless pages_domain.auto_ssl_enabled && pages_domain.auto_ssl_failed

          pages_domain.update!(auto_ssl_failed: false)
        end

        return unless updated

        PagesDomainSslRenewalWorker.perform_async(pages_domain.id)

        publish_event(pages_domain)
      end

      private

      def publish_event(domain)
        event = PagesDomainUpdatedEvent.new(
          data: {
            project_id: domain.project.id,
            namespace_id: domain.project.namespace_id,
            root_namespace_id: domain.project.root_namespace.id,
            domain_id: domain.id,
            domain: domain.domain
          }
        )

        Gitlab::EventStore.publish(event)
      end
    end
  end
end
