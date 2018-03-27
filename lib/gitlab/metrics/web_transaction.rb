module Gitlab
  module Metrics
    class WebTransaction < Transaction
      CONTROLLER_KEY = 'action_controller.instance'.freeze
      ENDPOINT_KEY = 'api.endpoint'.freeze

      CONTENT_TYPES = {
        'text/html' => :html,
        'text/plain' => :txt,
        'application/json' => :json,
        'text/js' => :js,
        'application/atom+xml' => :atom,
        'image/png' => :png,
        'image/jpeg' => :jpeg,
        'image/gif' => :gif,
        'image/svg+xml' => :svg
      }.freeze

      def initialize(env)
        super()
        @env = env
      end

      def labels
        return @labels if @labels

        # memoize transaction labels only source env variables were present
        @labels = if @env[CONTROLLER_KEY]
                    labels_from_controller || {}
                  elsif @env[ENDPOINT_KEY]
                    labels_from_endpoint || {}
                  end

        @labels || {}
      end

      private

      def labels_from_controller
        controller = @env[CONTROLLER_KEY]

        action = "#{controller.action_name}"
        suffix = CONTENT_TYPES[controller.content_type]

        if suffix && suffix != :html
          action += ".#{suffix}"
        end

        { controller: controller.class.name, action: action }
      end

      def labels_from_endpoint
        endpoint = @env[ENDPOINT_KEY]

        begin
          route = endpoint.route
        rescue
          # endpoint.route is calling env[Grape::Env::GRAPE_ROUTING_ARGS][:route_info]
          # but env[Grape::Env::GRAPE_ROUTING_ARGS] is nil in the case of a 405 response
          # so we're rescuing exceptions and bailing out
        end

        if route
          path = endpoint_paths_cache[route.request_method][route.path]
          { controller: 'Grape', action: "#{route.request_method} #{path}" }
        end
      end

      def endpoint_paths_cache
        @endpoint_paths_cache ||= Hash.new do |hash, http_method|
          hash[http_method] = Hash.new do |inner_hash, raw_path|
            inner_hash[raw_path] = endpoint_instrumentable_path(raw_path)
          end
        end
      end

      def endpoint_instrumentable_path(raw_path)
        raw_path.sub('(.:format)', '').sub('/:version', '')
      end
    end
  end
end
