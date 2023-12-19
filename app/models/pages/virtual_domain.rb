# frozen_string_literal: true

module Pages
  class VirtualDomain
    def initialize(projects:, trim_prefix: nil, domain: nil)
      @projects = projects
      @trim_prefix = trim_prefix
      @domain = domain
    end

    def certificate
      domain&.certificate
    end

    def key
      domain&.key
    end

    def lookup_paths
      projects.flat_map { |project| lookup_paths_for(project) }
    end

    private

    attr_reader :projects, :trim_prefix, :domain

    def lookup_paths_for(project)
      deployments_for(project).map do |deployment|
        Pages::LookupPath.new(
          deployment: deployment,
          trim_prefix: trim_prefix,
          domain: domain)
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
