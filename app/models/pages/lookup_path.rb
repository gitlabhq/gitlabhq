# frozen_string_literal: true

module Pages
  class LookupPath
    def initialize(project, domain: nil)
      @project = project
      @domain = domain
    end

    def project_id
      project.id
    end

    def access_control
      project.private_pages?
    end

    def https_only
      domain_https = domain ? domain.https? : true
      project.pages_https_only? && domain_https
    end

    def source
      {
        type: 'file',
        path: File.join(project.full_path, 'public/')
      }
    end

    def prefix
      '/'
    end

    private

    attr_reader :project, :domain
  end
end
