# frozen_string_literal: true

module QA
  module Resource
    class Job < Base
      attr_accessor :id, :name, :project

      attributes :id, :project, :status

      def fabricate_via_api!
        resource_web_url(api_get)
      rescue ResourceNotFoundError
        super
      end

      def artifacts
        parse_body(api_get_from(api_get_path))[:artifacts]
      end

      def api_get_path
        "/projects/#{project.id}/jobs/#{id}"
      end

      def api_trace_path
        "#{api_get_path}/trace"
      end

      def api_post_path; end

      def api_post_body
        {
          artifacts: artifacts
        }
      end

      # Job log
      def trace
        get(request_url(api_trace_path))
      end
    end
  end
end
