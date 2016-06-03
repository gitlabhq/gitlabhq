# A dumb middleware that returns a Go HTML document if the go-get=1 query string
# is used irrespective if the namespace/project exists
module Gitlab
  module Middleware
    class Go
      def initialize(app)
        @app = app
      end

      def call(env)
        request = Rack::Request.new(env)

        if go_request?(request)
          render_go_doc(request)
        else
          @app.call(env)
        end
      end

      private

      def render_go_doc(request)
        body = go_body(request)
        response = Rack::Response.new(body, 200, { 'Content-Type' => 'text/html' })
        response.finish
      end

      def go_request?(request)
        request["go-get"].to_i == 1 && request.env["PATH_INFO"].present?
      end

      def go_body(request)
        base_url = Gitlab.config.gitlab.url
        # Go subpackages may be in the form of namespace/project/path1/path2/../pathN
        # We can just ignore the paths and leave the namespace/project
        path_info = request.env["PATH_INFO"]
        path_info.sub!(/^\//, '')
        project_path = path_info.split('/').first(2).join('/')
        request_url = URI.join(base_url, project_path)
        domain_path = strip_url(request_url.to_s)

        "<!DOCTYPE html><html><head><meta content='#{domain_path} git #{request_url}.git' name='go-import'></head></html>\n";
      end

      def strip_url(url)
        url.gsub(/\Ahttps?:\/\//, '')
      end
    end
  end
end
