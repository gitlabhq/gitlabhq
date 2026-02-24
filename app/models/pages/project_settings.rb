# frozen_string_literal: true

module Pages
  class ProjectSettings
    def initialize(project)
      @project = project
    end

    def url
      project.pages_url
    end

    def deployments
      project.pages_deployments.active
    end

    def unique_domain_enabled?
      project.project_setting.pages_unique_domain_enabled?
    end

    def force_https?
      project.pages_https_only?
    end

    def pages_primary_domain
      project.project_setting.pages_primary_domain
    end

    private

    attr_reader :project
  end
end
