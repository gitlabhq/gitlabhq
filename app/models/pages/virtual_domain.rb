# frozen_string_literal: true

module Pages
  class VirtualDomain
    def initialize(projects, trim_prefix: nil, domain: nil)
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
      projects.map do |project|
        project.pages_lookup_path(trim_prefix: trim_prefix, domain: domain)
      end.sort_by(&:prefix).reverse
    end

    private

    attr_reader :projects, :trim_prefix, :domain
  end
end
