# frozen_string_literal: true

module QA
  module Resource
    class Deployment < Base
      attributes :id

      attr_accessor :project, :environment, :ref, :sha

      def resource_web_url(resource)
        super
      rescue ResourceURLMissingError
        # this particular resource does not expose a web_url property
      end

      def api_get_path
        "/projects/#{project.id}/deployments/#{id}"
      end

      def api_post_path
        "/projects/#{project.id}/deployments"
      end

      def api_post_body
        {
          environment: environment,
          ref: ref,
          sha: sha,
          tag: false,
          status: 'running'
        }
      end

      def succeed!
        api_put_to(api_get_path, status: 'success')
      end
    end
  end
end
