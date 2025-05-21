# frozen_string_literal: true

module Projects
  module PagesHelper
    def can_create_pages_custom_domains?(current_user, project)
      current_user.can?(:update_pages, project) &&
        (Gitlab.config.pages.external_http ||
          Gitlab.config.pages.external_https ||
          pages_custom_domain_enabled?) &&
        project.can_create_custom_domains?
    end

    def pages_custom_domain_enabled?
      custom_domain_mode = Gitlab.config.pages.custom_domain_mode
      allowed_values = %w[http https]

      allowed_values.include?(custom_domain_mode.to_s.downcase)
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
