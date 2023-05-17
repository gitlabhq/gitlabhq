# frozen_string_literal: true

module Gitlab
  module Pages
    class VirtualHostFinder
      def initialize(host)
        @host = host&.downcase
      end

      def execute
        return if host.blank?

        gitlab_host = ::Settings.pages.host.downcase.prepend(".")

        if host.ends_with?(gitlab_host)
          name = host.delete_suffix(gitlab_host)

          by_namespace_domain(name) ||
            by_unique_domain(name)
        else
          by_custom_domain(host)
        end
      end

      private

      attr_reader :host

      def by_unique_domain(name)
        project = Project.by_pages_enabled_unique_domain(name)

        return unless Feature.enabled?(:pages_unique_domain, project)
        return unless project&.pages_deployed?

        ::Pages::VirtualDomain.new(projects: [project])
      end

      def by_namespace_domain(name)
        namespace = Namespace.top_most.by_path(name)

        return if namespace.blank?

        cache = if Feature.enabled?(:cache_pages_domain_api, namespace)
                  ::Gitlab::Pages::CacheControl.for_namespace(namespace.id)
                end

        ::Pages::VirtualDomain.new(
          trim_prefix: namespace.full_path,
          projects: namespace.all_projects_with_pages,
          cache: cache
        )
      end

      def by_custom_domain(host)
        domain = PagesDomain.find_by_domain_case_insensitive(host)

        return unless domain&.pages_deployed?

        cache = if Feature.enabled?(:cache_pages_domain_api, domain.project.root_namespace)
                  ::Gitlab::Pages::CacheControl.for_domain(domain.id)
                end

        ::Pages::VirtualDomain.new(
          projects: [domain.project],
          domain: domain,
          cache: cache
        )
      end
    end
  end
end
