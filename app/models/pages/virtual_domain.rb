# frozen_string_literal: true

module Pages
  class VirtualDomain
    def initialize(projects:, cache: nil, trim_prefix: nil, domain: nil)
      @projects = projects
      @cache = cache
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

    # cache_key is required by #present_cached in ::API::Internal::Pages
    def cache_key
      @cache_key ||= cache&.cache_key
    end

    private

    attr_reader :projects, :trim_prefix, :domain, :cache

    def lookup_paths_for(project)
      Pages::LookupPath.new(project, trim_prefix: trim_prefix, domain: domain)
    end
  end
end
