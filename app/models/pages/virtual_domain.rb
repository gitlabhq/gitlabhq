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
      projects
        .map { |project| lookup_paths_for(project) }
        .select(&:source) # TODO: remove in https://gitlab.com/gitlab-org/gitlab/-/issues/328715
        .sort_by(&:prefix)
        .reverse
    end

    private

    attr_reader :projects, :trim_prefix, :domain

    def lookup_paths_for(project)
      Pages::LookupPath.new(project, trim_prefix: trim_prefix, domain: domain)
    end
  end
end
