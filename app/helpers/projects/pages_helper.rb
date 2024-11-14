# frozen_string_literal: true

module Projects
  module PagesHelper
    def can_create_pages_custom_domains?(current_user, project)
      current_user.can?(:update_pages, project) &&
        (Gitlab.config.pages.external_http || Gitlab.config.pages.external_https) &&
        project.can_create_custom_domains?
    end

    def pages_subdomain(project)
      Gitlab::Pages::UrlBuilder
        .new(project)
        .project_namespace
    end

    def build_pages_url(project)
      Gitlab::Pages::UrlBuilder
        .new(project)
        .pages_url
    end
  end
end
