# frozen_string_literal: true

module Tasks
  module Gitlab
    module Permissions
      module Routes
        class DocsTask
          REQUEST_METHOD_SORT_ORDER = { GET: 0, POST: 1, PATCH: 2, PUT: 3, HEAD: 4, DELETE: 5 }.freeze
          BOUNDARY_SORT_ORDER = { project: 0, group: 1, user: 2, instance: 3 }.freeze

          def initialize
            all_routes = ::API::API.endpoints.flat_map(&:routes)
            @routes = build_route_structs(all_routes)
            @skipped_routes = all_routes.select do |r|
              r.settings.dig(:authorization, :skip_granular_token_authorization)
            end
            @doc_path = Rails.root.join('doc/auth/tokens/fine_grained_access_tokens.md')
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

          def skipped_endpoints
            sorted = skipped_routes.sort_by do |r|
              [route_path(r), REQUEST_METHOD_SORT_ORDER[r.request_method.to_sym]]
            end

            build_table(%w[Method Path]) do
              sorted.map do |r|
                markdown_row(["`#{r.request_method}`", "`#{route_path(r)}`"])
              end
            end
          end

          private

          attr_reader :routes, :skipped_routes, :doc_path, :template_path

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

          def route_path(route)
            route.origin.delete_prefix('/api/:version')
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
            route_columns = ["`#{route.request_method}`", "`#{route_path(route)}`"]
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

            footnotes = []

            table = build_table(%w[Action Access Method Path]) do
              table_body = []

              group_routes_by_action(resource_routes).each do |action, action_routes|
                action_column = action

                group_routes_by_boundary(action_routes).each do |(boundary, boundary_routes)|
                  sort_routes_by_request_method(boundary_routes).each do |r|
                    additional_permissions = r.permissions[1..]
                    if additional_permissions.present?
                      footnote = additional_permissions.map do |p|
                        "`#{p.action&.titleize} #{p.resource_name}`"
                      end.join(', ')
                      footnotes << footnote unless footnotes.include?(footnote)
                      footnote_index = footnotes.index(footnote) + 1
                      action_display = "#{action_column} <sup>#{footnote_index}</sup>"
                    else
                      action_display = action_column
                    end

                    base_columns = [action_display, boundary.to_s.humanize]
                    table_body << build_route_row(base_columns, r.route)
                  end
                end
              end

              table_body
            end

            parts = [title, description, table]

            if footnotes.any?
              footnote_lines = footnotes.map.with_index(1) do |names, index|
                "<sup>#{index}</sup> Also requires the #{names} permission."
              end
              parts << "\n#{footnote_lines.join("\n")}"
            end

            parts.join("\n")
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
