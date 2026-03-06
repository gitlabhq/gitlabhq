# frozen_string_literal: true

module Tasks
  module Gitlab
    module Permissions
      module Routes
        class CleanupTodoTask
          TODO_FILE = Rails.root.join('config/authz/routes/authorization_todo.txt')

          def run
            stale = stale_entries
            if stale.empty?
              puts "No stale entries found in #{TODO_FILE}"
              return
            end

            rewrite_todo_file(stale)
            puts "Removed #{stale.size} stale entries from #{TODO_FILE}:"
            stale.each { |entry| puts "  - #{entry}" }
          end

          def stale_entries
            return [] unless TODO_FILE.exist?

            route_map = build_route_map
            todo_entries.select { |entry| stale?(entry, route_map) }
          end

          private

          def todo_entries
            @todo_entries ||= TODO_FILE.readlines.each_with_object([]) do |line, list|
              stripped = line.strip
              list << stripped unless stripped.empty? || stripped.start_with?('#')
            end
          end

          def build_route_map
            API::API.endpoints.flat_map(&:routes).each_with_object({}) do |route, map|
              map[route_id(route)] = has_authorization?(route.settings[:authorization])
            end
          end

          def stale?(entry, route_map)
            !route_map.key?(entry) || route_map[entry]
          end

          def route_id(route)
            "#{route.request_method} #{route.origin.delete_prefix('/api/:version')}"
          end

          def has_authorization?(authorization)
            return false unless authorization

            Array(authorization[:permissions]).any? || authorization[:skip_granular_token_authorization]
          end

          def rewrite_todo_file(stale)
            stale_set = stale.to_set
            lines = TODO_FILE.readlines.reject do |line|
              stripped = line.strip
              stale_set.include?(stripped)
            end

            TODO_FILE.write(lines.join)
          end
        end
      end
    end
  end
end
