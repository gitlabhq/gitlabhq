# frozen_string_literal: true

module QA
  module Resource
    class Release < Base
      attr_accessor :project, :tag_name, :ref, :name, :description

      def resource_web_url(resource)
        super
      rescue ResourceURLMissingError
        # this particular resource does not expose a web_url property
      end

      def api_get_path
        "/projects/#{project.id}/releases/#{CGI.escape(tag_name)}"
      end

      def api_delete_path
        api_get_path
      end

      def api_post_path
        "/projects/#{project.id}/releases"
      end

      def api_post_body
        {
          tag_name: tag_name,
          ref: ref,
          name: name,
          description: description
        }.compact
      end
    end
  end
end
