module Gitlab
  module Badge
    module Coverage
      ##
      # Class that describes coverage badge metadata
      #
      class Metadata
        include Gitlab::Application.routes.url_helpers
        include ActionView::Helpers::AssetTagHelper
        include ActionView::Helpers::UrlHelper

        def initialize(badge)
          @project = badge.project
          @ref = badge.ref
          @job = badge.job
        end

        def to_html
          link_to(image_tag(image_url, alt: 'coverage report'), link_url)
        end

        def to_markdown
          "[![coverage report](#{image_url})](#{link_url})"
        end

        def image_url
          coverage_namespace_project_badges_url(@project.namespace,
                                                @project, @ref,
                                                format: :svg)
        end

        def link_url
          namespace_project_commits_url(@project.namespace, @project, id: @ref)
        end
      end
    end
  end
end
