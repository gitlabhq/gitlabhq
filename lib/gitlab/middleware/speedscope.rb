# frozen_string_literal: true

module Gitlab
  module Middleware
    class Speedscope
      def initialize(app)
        @app = app
      end

      def call(env)
        request = Rack::Request.new(env)

        if request.params['performance_bar'] == 'flamegraph' && Gitlab::PerformanceBar.allowed_for_user?(request.env['warden'].user)
          body = nil

          Gitlab::SafeRequestStore[:capturing_flamegraph] = true

          require 'stackprof'

          flamegraph = ::StackProf.run(
            mode: :wall,
            raw: true,
            aggregate: false,
            interval: (0.5 * 1000).to_i
          ) do
            _, _, body = @app.call(env)
          end

          path = env['PATH_INFO'].sub('//', '/')
          body.close if body.respond_to?(:close)

          return flamegraph(flamegraph, path)
        end

        @app.call(env)
      end

      def flamegraph(graph, path)
        headers = { 'Content-Type' => 'text/html' }

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
              <script type="text/javascript">
                var graph = #{Gitlab::Json.generate(graph)};
                var json = JSON.stringify(graph);
                var blob = new Blob([json], { type: 'text/plain' });
                var objUrl = encodeURIComponent(URL.createObjectURL(blob));
                var iframe = document.createElement('IFRAME');
                iframe.setAttribute('id', 'speedscope-iframe');
                document.body.appendChild(iframe);
                var iframeUrl = '#{Gitlab.config.gitlab.relative_url_root}/assets/speedscope/index.html#profileURL=' + objUrl + '&title=' + 'Flamegraph for #{CGI.escape(path)}';
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
