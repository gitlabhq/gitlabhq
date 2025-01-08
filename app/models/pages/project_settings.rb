# frozen_string_literal: true

module Pages
  class ProjectSettings
    def initialize(project)
      @project = project
    end

    def url = url_builder.pages_url

    def deployments = project.pages_deployments.active

    def unique_domain_enabled? = project.project_setting.pages_unique_domain_enabled?

    def force_https? = project.pages_https_only?

    def pages_primary_domain = project.project_setting.pages_primary_domain

    private

    attr_reader :project

    def url_builder
      @url_builder ||= ::Gitlab::Pages::UrlBuilder.new(project)
    end
  end
end
