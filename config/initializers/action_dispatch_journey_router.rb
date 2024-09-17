# frozen_string_literal: true

module ActionDispatch
  module Journey
    class Router
      private

      # Besides the patch, this method is a duplicate for the original method defined in Rails:
      # https://github.com/rails/rails/blob/v7.0.5/actionpack/lib/action_dispatch/journey/router.rb#L109-L132
      # See https://github.com/rails/rails/issues/47244
      def find_routes(req)
        path_info = req.path_info
        routes = filter_routes(path_info).concat custom_routes.find_all { |r|
          r.path.match?(path_info)
        }

        if req.head?
          routes = match_head_routes(routes, req)
        else
          routes.select! { |r| r.matches?(req) }
        end

        routes.sort_by!(&:precedence)

        routes.map! do |r|
          match_data = r.path.match(path_info)
          path_parameters = {}

          # This is the patch we are adding. This handles routes where `r.matches?` above is true
          # but the route does not actually match due to other constraints
          #
          # Without this line the following error is raised:
          #
          # NoMethodError:
          #   undefined method `names' for nil:NilClass
          #
          # The behavior is covered by spec/initializers/action_dispatch_journey_router_spec.rb
          next if match_data.nil?

          match_data.names.each_with_index do |name, i|
            val = match_data[i + 1]
            path_parameters[name.to_sym] = Utils.unescape_uri(val) if val
          end

          # This is the minimal version to support both Rails 7.0 and Rails 7.1
          #
          # - https://github.com/rails/rails/blob/v7.1.3.4/actionpack/lib/action_dispatch/journey/router.rb#L131
          #
          # - https://github.com/rails/rails/blob/v7.0.8.4/actionpack/lib/action_dispatch/journey/router.rb#L130
          #
          # After the upgrade, this method can be more like the v7.1.3.4 version
          if Gitlab.next_rails?
            yield [match_data, path_parameters, r]
          else
            [match_data, path_parameters, r]
          end
        end.compact!

        routes
      end
    end
  end
end
