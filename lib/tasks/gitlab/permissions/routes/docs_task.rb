# frozen_string_literal: true

module Tasks
  module Gitlab
    module Permissions
      module Routes
        class DocsTask
          REQUEST_METHOD_SORT_ORDER = { GET: 0, POST: 1, PATCH: 2, PUT: 3, HEAD: 4, DELETE: 5 }.freeze
          BOUNDARY_SORT_ORDER = { project: 0, group: 1, user: 2, instance: 3 }.freeze

          def initialize
            @routes = build_route_structs(::API::API.endpoints.flat_map(&:routes))
            @doc_path = Rails.root.join('doc/development/permissions/granular_pat_rest_api_endpoints.md')
            @template_path =
              Rails.root.join('tooling/authz/permissions/docs/templates/granular_pat_rest_api_endpoints.md.erb')
          end

          def check_docs
            doc = File.read(doc_path)

            template = ERB.new(File.read(template_path))
            if doc == template.result(binding)
              puts 'Granular Personal Access Token allowed endpoints documentation is up to date.'
            else
              puts '##########'
              puts '#'
              puts '# Granular Personal Access Token allowed endpoints documentation is outdated! Please update it ' \
                'by running `bundle exec rake gitlab:permissions:routes:compile_docs`.'
              puts '#'
              puts '##########'

              abort
            end
          end

          def compile_docs
            template = ERB.new(File.read(template_path))
            File.write(doc_path, template.result(binding))
            puts 'Granular Personal Access Token allowed endpoints documentation compiled.'
          end

          def allowed_endpoints
            routes_by_category = routes.group_by(&:category).sort.to_h

            build_section(nil, nil, routes_by_category) do |subsection, subsection_routes|
              build_category_section(subsection, subsection_routes)
            end
          end

          private

          attr_reader :routes, :doc_path, :template_path

          # Build routes as a collection of structs, each representing a route
          # with its associated permissions, category, resource, and action. If
          # a route has multiple boundaries it results to multiple structs, one
          # for each boundary. This makes it possible to do
          # routes.group_by(&:(category|resource|action)) instead of
          # routes.group_by { |r| compute_group_by_attr_for_route(r) }.
          def build_route_structs(routes)
            routes = routes.select do |r|
              route_permissions(r).compact_blank.present?
            end

            routes.flat_map do |r|
              permissions = route_permissions(r)
              primary_permission = permissions.first
              primary_category = primary_permission.category_name || 'Uncategorized'
              primary_resource = primary_permission.resource_name || 'Unknown resource'
              primary_resource_description = primary_permission.resource_description || ''
              primary_action = primary_permission.action&.titleize || 'Unknown action'

              boundaries_for_route(r).map do |boundary|
                Struct.new(:route, :category, :resource, :resource_description, :action, :boundary, :permissions).new(
                  r,
                  primary_category,
                  primary_resource,
                  primary_resource_description,
                  primary_action,
                  boundary,
                  permissions
                )
              end
            end
          end

          def route_permissions(route)
            Array(route.settings.dig(:authorization, :permissions)).map do |p|
              ::Authz::PermissionGroups::Assignable.for_permission(p).first
            end
          end

          def boundaries_for_route(route)
            [
              route.settings.dig(:authorization, :boundary_type),
              Array(route.settings.dig(:authorization, :boundaries)).pluck(:boundary_type)
            ].flatten.compact_blank.uniq
          end

          def markdown_row(row)
            "| #{row.join(' | ')} |"
          end

          def build_table(header)
            table = []
            table << markdown_row(header)
            table << markdown_row(header.map { |item| '-' * item.length })
            table += yield
            table.join("\n")
          end

          def build_section(title, description, routes)
            subsections = routes.map.with_index do |(subsection, subsection_routes), index|
              subsection = yield(subsection, subsection_routes)
              subsection += "\n" unless index == routes.size - 1
              subsection
            end.join("\n")

            [title, description, subsections].compact.join("\n")
          end

          def build_route_row(base_columns, route)
            route_columns = ["`#{route.request_method}`", "`#{route.origin.delete_prefix('/api/:version')}`"]
            markdown_row(base_columns + route_columns)
          end

          def sort_routes_by_request_method(routes)
            routes.sort_by do |r|
              REQUEST_METHOD_SORT_ORDER[r.route.request_method.to_sym]
            end
          end

          def group_routes_by_boundary(routes)
            routes.group_by(&:boundary).sort_by do |b, _|
              BOUNDARY_SORT_ORDER[b.to_sym]
            end.to_h
          end

          def group_routes_by_action(routes)
            routes.group_by(&:action).sort.to_h
          end

          def build_resource_section(resource, resource_routes)
            title = "#### #{resource}\n"
            description = "#{resource_routes.first.resource_description}\n"

            table = build_table(%w[Action Access Method Path]) do
              table_body = []

              group_routes_by_action(resource_routes).each do |action, action_routes|
                action_column = action

                group_routes_by_boundary(action_routes).each_with_index do |(boundary, boundary_routes), boundary_index|
                  action_column = ' ' if boundary_index > 0

                  sort_routes_by_request_method(boundary_routes).each_with_index do |r, route_pos|
                    base_columns = route_pos > 0 ? [' ', ' '] : [action_column, boundary.to_s.humanize]
                    table_body << build_route_row(base_columns, r.route)
                  end
                end
              end

              table_body
            end

            [title, description, table].join("\n")
          end

          def build_category_section(category, category_routes)
            title = "### #{category} resources\n"
            routes_by_resource = category_routes.group_by(&:resource).sort.to_h

            build_section(title, nil, routes_by_resource) do |subsection, subsection_routes|
              build_resource_section(subsection, subsection_routes)
            end
          end
        end
      end
    end
  end
end
