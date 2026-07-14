# frozen_string_literal: true

module Tasks
  module Gitlab
    module Permissions
      # Markdown rendering primitives shared by the granular-token documentation
      # tasks (Routes::DocsTask and Graphql::DocsTask).
      module MarkdownTable
        BOUNDARY_SORT_ORDER = { project: 0, group: 1, user: 2, instance: 3 }.freeze

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

        def build_section(title, description, sections)
          subsections = sections.map.with_index do |(subsection, subsection_items), index|
            subsection = yield(subsection, subsection_items)
            subsection += "\n" unless index == sections.size - 1
            subsection
          end.join("\n")

          [title, description, subsections].compact.join("\n")
        end

        def build_category_sections(records)
          build_section(nil, nil, group_and_sort(records, :category)) do |category, category_records|
            build_category_section(category, category_records)
          end
        end

        def build_category_section(category, category_records)
          title = "### #{category} resources\n"

          build_section(title, nil, group_and_sort(category_records, :resource)) do |resource, resource_records|
            build_resource_section(resource, resource_records)
          end
        end

        def group_and_sort(records, attribute)
          records
            .group_by(&attribute)
            .sort_by { |key, _| [key.to_s.downcase, key.to_s] }
            .to_h
        end
      end
    end
  end
end
