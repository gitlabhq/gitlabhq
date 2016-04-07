module Gitlab
  module Badge
    ##
    # Build badge
    #
    class Build
      include Gitlab::Application.routes.url_helpers
      include ActionView::Helpers::AssetTagHelper
      include ActionView::Helpers::UrlHelper

      def initialize(project, ref)
        @project, @ref = project, ref
        @image = ::Ci::ImageForBuildService.new.execute(project, ref: ref)
      end

      def type
        'image/svg+xml'
      end

      def data
        File.read(@image[:path])
      end

      def to_s
        @image[:name].sub(/\.svg$/, '')
      end

      def to_html
        link_to(image_tag(image_url, alt: 'build status'), link_url)
      end

      def to_markdown
        "[![build status](#{image_url})](#{link_url})"
      end

      def image_url
        build_namespace_project_badges_url(@project.namespace,
                                           @project, @ref, format: :svg)
      end

      def link_url
        namespace_project_commits_url(@project.namespace, @project, id: @ref)
      end
    end
  end
end
