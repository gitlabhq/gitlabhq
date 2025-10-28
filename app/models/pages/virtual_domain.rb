# frozen_string_literal: true

module Pages
  class VirtualDomain
    include Gitlab::Utils::StrongMemoize

    def initialize(projects:, trim_prefix: nil, domain: nil, namespace: nil)
      @projects = projects
      @trim_prefix = trim_prefix
      @domain = domain
      @namespace = namespace
    end

    def certificate
      domain&.certificate
    end

    def key
      domain&.key
    end

    def root_namespace_id
      @namespace&.root_ancestor&.id
    end

    def lookup_paths
      projects.flat_map { |project| lookup_paths_for(project, root_namespace_id) }
    end

    private

    attr_reader :projects, :trim_prefix, :domain

    def access_control_for(project)
      return false unless Gitlab.config.pages.access_control
      return true if ::Gitlab::Pages.access_control_is_forced?
      return true if project.project_feature&.private_pages?

      pages_access_control_trie&.covered?(project.namespace.traversal_ids)
    end

    def pages_access_control_trie
      @namespace&.pages_access_control_trie
    end
    strong_memoize_attr :pages_access_control_trie

    def lookup_paths_for(project, root_namespace_id)
      deployments_for(project).map do |deployment|
        Pages::LookupPath.new(
          deployment: deployment,
          root_namespace_id: root_namespace_id,
          trim_prefix: trim_prefix,
          domain: domain,
          access_control: access_control_for(project)
        )
      end
    end

    def deployments_for(project)
      if ::Gitlab::Pages.multiple_versions_enabled_for?(project)
        project.active_pages_deployments
      else
        # project.active_pages_deployments is already loaded from the database,
        # so finding from the array to avoid N+1
        project
          .active_pages_deployments
          .to_a
          .find { |deployment| deployment.path_prefix.blank? }
          .then { |deployment| [deployment] }
      end
    end
  end
end
