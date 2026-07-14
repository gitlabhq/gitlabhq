# frozen_string_literal: true

module Tasks
  module Gitlab
    module Permissions
      module Graphql
        # Generates the GraphQL counterpart to Routes::DocsTask.
        #
        # Where Routes::DocsTask reads granular-token permissions from Grape route
        # settings, this task reads them from the `GranularScope` directives applied
        # to GraphQL types, mutations, and fields. Both map each permission to its
        # assignable permission group (category/resource/action) so the two pages
        # share the same structure.
        class DocsTask
          include SchemaDirectives
          include ::Tasks::Gitlab::Permissions::MarkdownTable

          KIND_SORT_ORDER = { 'Type' => 0, 'Mutation' => 1, 'Field' => 2 }.freeze

          Item = Struct.new(:kind, :name, :category, :resource, :resource_description, :action, :boundary, :permissions)

          def initialize
            @items = build_items
            @doc_path = Rails.root.join('doc/auth/tokens/fine_grained_access_tokens_graphql.md')
            @template_path =
              Rails.root.join('tooling/authz/permissions/docs/templates/granular_pat_graphql_fields.md.erb')
          end

          def check_docs
            doc = File.read(doc_path)

            template = ERB.new(File.read(template_path))
            if doc == template.result(binding)
              puts 'GraphQL field documentation is up-to-date'
            else
              puts '##########'
              puts '#'
              puts '# GraphQL field documentation is outdated! Please update it ' \
                'by running `bundle exec rake gitlab:permissions:graphql:compile_docs`.'
              puts '#'
              puts '##########'

              abort
            end
          end

          def compile_docs
            template = ERB.new(File.read(template_path))
            File.write(doc_path, template.result(binding))
            puts 'GraphQL field documentation compiled'
          end

          def allowed_fields
            build_category_sections(items)
          end

          private

          attr_reader :items, :doc_path, :template_path

          # Builds one Item per GraphQL element (type, mutation, or field) that
          # carries a GranularScope directive. The primary permission group
          # supplies the category/resource/action; any additional groups are
          # rendered as footnotes, mirroring Routes::DocsTask.
          def build_items
            items = []

            each_granular_directive do |element, directive|
              permissions = permission_groups(directive)
              next if permissions.empty?

              primary = permissions.first
              items << Item.new(
                element[:kind].capitalize,
                element[:name],
                primary.category_name || 'Uncategorized',
                primary.resource_name || 'Unknown resource',
                primary.resource_description || '',
                primary.action&.titleize || 'Unknown action',
                boundary_for(directive),
                permissions
              )
            end

            items.uniq { |i| [i.category, i.resource, i.action, i.boundary, i.kind, i.name] }
          end

          def permission_groups(directive)
            Array(directive.arguments[:permissions]).filter_map do |permission|
              ::Authz::PermissionGroups::Assignable.available_for_permission(permission.to_s.downcase.to_sym).first
            end
          end

          def boundary_for(directive)
            directive.arguments[:boundary_type].to_s.downcase.presence || 'unknown'
          end

          def build_resource_section(resource, resource_items)
            title = "#### #{resource}\n"
            description = "#{resource_items.first.resource_description}\n"
            footnotes = []

            table = build_table(%w[Action Access Kind Name]) do
              group_by_action(resource_items).flat_map do |action, action_items|
                group_by_boundary(action_items).flat_map do |boundary, boundary_items|
                  sort_by_kind(boundary_items).map do |item|
                    action_column = action_with_footnote(action, item, footnotes)
                    markdown_row([action_column, boundary.to_s.humanize, item.kind, "`#{item.name}`"])
                  end
                end
              end
            end

            parts = [title, description, table]
            parts << footnote_lines(footnotes) if footnotes.any?
            parts.join("\n")
          end

          # Marks an action with a footnote reference when the element requires
          # more than its primary permission, registering the footnote text.
          def action_with_footnote(action, item, footnotes)
            additional_permissions = item.permissions[1..]
            return action if additional_permissions.blank?

            footnote = additional_permissions.map { |p| "`#{p.action&.titleize} #{p.resource_name}`" }.join(', ')
            footnotes << footnote unless footnotes.include?(footnote)

            "#{action} <sup>#{footnotes.index(footnote) + 1}</sup>"
          end

          def footnote_lines(footnotes)
            lines = footnotes.map.with_index(1) do |names, index|
              "<sup>#{index}</sup> Also requires the #{names} permission."
            end

            "\n#{lines.join("\n")}"
          end

          def group_by_action(items)
            items.group_by(&:action).sort.to_h
          end

          def group_by_boundary(items)
            items.group_by(&:boundary).sort_by { |b, _| BOUNDARY_SORT_ORDER.fetch(b.to_sym, 99) }.to_h
          end

          def sort_by_kind(items)
            items.sort_by { |i| [KIND_SORT_ORDER.fetch(i.kind, 99), i.name] }
          end
        end
      end
    end
  end
end
