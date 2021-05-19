# frozen_string_literal: true

module Gitlab
  module Middleware
    class Speedscope
      def initialize(app)
        @app = app
      end

      def call(env)
        request = ActionDispatch::Request.new(env)

        return @app.call(env) unless rendering_flamegraph?(request)

        body = nil

        ::Gitlab::SafeRequestStore[:capturing_flamegraph] = true

        require 'stackprof'

        begin
          flamegraph = ::StackProf.run(
            mode: :wall,
            raw: true,
            aggregate: false,
            interval: ::Gitlab::StackProf::DEFAULT_INTERVAL_US
          ) do
            _, _, body = @app.call(env)
          end
        ensure
          body.close if body.respond_to?(:close)
        end

        render_flamegraph(flamegraph, request)
      end

      private

      def rendering_flamegraph?(request)
        request.params['performance_bar'] == 'flamegraph' && ::Gitlab::PerformanceBar.allowed_for_user?(request.env['warden']&.user)
      end

      def render_flamegraph(graph, request)
        headers = { 'Content-Type' => 'text/html' }
        path = request.env['PATH_INFO'].sub('//', '/')

        speedscope_path = ::Gitlab::Utils.append_path(::Gitlab.config.gitlab.relative_url_root, '/-/speedscope/index.html')

        html = <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <style>
                body { margin: 0; height: 100vh; }
                #speedscope-iframe { width: 100%; height: 100%; border: none; }
              </style>
            </head>
            <body>
              <script type="text/javascript" nonce="#{request.content_security_policy_nonce}">
                var graph = #{Gitlab::Json.generate(graph)};
                var json = JSON.stringify(graph);
                var blob = new Blob([json], { type: 'text/plain' });
                var objUrl = encodeURIComponent(URL.createObjectURL(blob));
                var iframe = document.createElement('IFRAME');
                iframe.setAttribute('id', 'speedscope-iframe');
                document.body.appendChild(iframe);
                var iframeUrl = '#{speedscope_path}#profileURL=' + objUrl + '&title=' + 'Flamegraph for #{CGI.escape(path)}';
                iframe.setAttribute('src', iframeUrl);
              </script>
            </body>
          </html>
        HTML

        [200, headers, [html]]
      end
    end
  end
end
