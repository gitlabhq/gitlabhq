# frozen_string_literal: true

module QA
  module Resource
    class Tag < Base
      attr_accessor :project, :name, :ref

      def resource_web_url(resource)
        super
      rescue ResourceURLMissingError
        # this particular resource does not expose a web_url property
      end

      def api_get_path
        "/projects/#{project.id}/repository/tags/#{name}"
      end

      def api_post_path
        "/projects/#{project.id}/repository/tags"
      end

      def api_post_body
        {
          tag_name: name,
          ref: ref
        }
      end
    end
  end
end
