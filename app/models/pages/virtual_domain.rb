# frozen_string_literal: true

module Pages
  class VirtualDomain
    def initialize(projects, domain: nil)
      @projects = projects
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
        project.pages_lookup_path(domain: domain)
      end.sort_by(&:prefix).reverse
    end

    private

    attr_reader :projects, :domain
  end
end
