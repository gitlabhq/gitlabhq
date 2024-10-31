# frozen_string_literal: true

module Gitlab
  module Pages
    class VirtualHostFinder
      def initialize(host)
        @host = host&.downcase
      end

      def execute
        return if host.blank?

        gitlab_host = ::Gitlab.config.pages.host.downcase.prepend(".")

        if host.ends_with?(gitlab_host)
          name = host.delete_suffix(gitlab_host)

          by_unique_domain(name) || by_namespace_domain(name)
        else
          by_custom_domain(host)
        end
      end

      private

      attr_reader :host

      def by_unique_domain(name)
        project = Project.by_pages_enabled_unique_domain(name)

        return unless project&.pages_deployed?

        ::Pages::VirtualDomain.new(projects: [project])
      end

      def by_namespace_domain(name)
        namespace = Namespace.top_level.by_path(name)

        return if namespace.blank?

        ::Pages::VirtualDomain.new(
          trim_prefix: namespace.full_path,
          projects: namespace.all_projects_with_pages)
      end

      def by_custom_domain(host)
        domain = PagesDomain.find_by_domain_case_insensitive(host)

        return unless domain&.enabled?
        return unless domain&.pages_deployed?

        ::Pages::VirtualDomain.new(projects: [domain.project], domain: domain)
      end
    end
  end
end
