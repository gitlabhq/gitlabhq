# frozen_string_literal: true

module Pages
  module Domains
    class CreateService < BaseService
      def execute
        return unless authorized?

        existing_domain = find_existing_domain

        if existing_domain
          domain = PagesDomain.new(domain: params[:domain])
          error_message = if current_user.can?(:admin_pages, existing_domain.project)
                            "is already in use by project #{existing_domain.project.full_path}"
                          else
                            "is already in use by another project"
                          end

          domain.errors.add(:domain, error_message)
          return domain
        end

        domain = project.pages_domains.create(params)

        publish_event(domain) if domain.persisted?

        domain
      end

      private

      def authorized?
        current_user.can?(:update_pages, project)
      end

      def find_existing_domain
        PagesDomain.find_by_domain_case_insensitive(params[:domain])
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
end
