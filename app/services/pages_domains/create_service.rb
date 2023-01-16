# frozen_string_literal: true

module PagesDomains
  class CreateService < BaseService
    def execute
      return unless authorized?

      domain = project.pages_domains.create(params)

      publish_event(domain) if domain.persisted?

      domain
    end

    private

    def authorized?
      current_user.can?(:update_pages, project)
    end

    def publish_event(domain)
      event = PagesDomainCreatedEvent.new(
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
