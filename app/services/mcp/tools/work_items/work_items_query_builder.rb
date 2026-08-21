# frozen_string_literal: true

module Mcp
  module Tools
    module WorkItems
      # Composes the namespace.workItems query and variables shared by the work-item list tools.
      class WorkItemsQueryBuilder
        COMPOSITE_FILTERS = %w[not or].freeze
        DEFAULT_PAGE_SIZE = 20
        QUERY_NAMES = { full: 'GetWorkItemsFull', compact: 'GetWorkItemsCompact' }.freeze

        class << self
          # Single source of truth for all filter definitions.
          # Adding a new filter = adding one entry here (or in the EE override).
          # Each entry: { key: 'graphqlArgName', type: 'GraphQLType' }
          def filter_definitions
            [
              { key: 'assigneeUsernames',   type: '[String!]' },
              { key: 'assigneeWildcardId',  type: 'AssigneeWildcardId' },
              { key: 'authorUsername',      type: 'String' },
              { key: 'confidential',        type: 'Boolean' },
              { key: 'hierarchyFilters',    type: 'HierarchyFilterInput' },
              { key: 'labelName',           type: '[String!]' },
              { key: 'milestoneTitle',      type: '[String!]' },
              { key: 'milestoneWildcardId', type: 'MilestoneWildcardId' },
              { key: 'myReactionEmoji',     type: 'String' },
              { key: 'types',               type: '[IssueType!]' },
              { key: 'state',               type: 'IssuableState' },
              { key: 'search',              type: 'String' },
              { key: 'in',                  type: '[IssuableSearchableField!]' },
              { key: 'closedAfter',          type: 'Time' },
              { key: 'closedBefore',         type: 'Time' },
              { key: 'createdAfter',         type: 'Time' },
              { key: 'createdBefore',        type: 'Time' },
              { key: 'dueAfter',             type: 'Time' },
              { key: 'dueBefore',            type: 'Time' },
              { key: 'updatedAfter',         type: 'Time' },
              { key: 'updatedBefore',        type: 'Time' },
              { key: 'subscribed',           type: 'SubscriptionStatus' },
              { key: 'releaseTag',           type: '[String!]' },
              { key: 'releaseTagWildcardId', type: 'ReleaseTagWildcardId' },
              { key: 'crmContactId',         type: 'String' },
              { key: 'crmOrganizationId',    type: 'String' },
              { key: 'not',                 type: 'NegatedWorkItemFilterInput' },
              { key: 'or',                  type: 'UnionedWorkItemFilterInput' }
            ]
          end

          def widget_fragments
            [
              <<~GRAPHQL.indent(12),
                ... on WorkItemWidgetAssignees {
                  assignees {
                    nodes {
                      id
                      name
                      username
                      webUrl
                    }
                  }
                }
              GRAPHQL
              <<~GRAPHQL.indent(12),
                ... on WorkItemWidgetLabels {
                  labels {
                    nodes {
                      id
                      title
                      color
                      description
                    }
                  }
                }
              GRAPHQL
              <<~GRAPHQL.indent(12),
                ... on WorkItemWidgetMilestone {
                  milestone {
                    id
                    title
                    dueDate
                    startDate
                  }
                }
              GRAPHQL
              <<~GRAPHQL.indent(12),
                ... on WorkItemWidgetStartAndDueDate {
                  dueDate
                  startDate
                }
              GRAPHQL
              <<~GRAPHQL.indent(12)
                ... on WorkItemWidgetHierarchy {
                  parent {
                    id
                  }
                }
              GRAPHQL
            ]
          end

          def build_query(projection: :full)
            filter_vars = filter_definitions.map { |f| "  $#{f[:key]}: #{f[:type]}" }.join("\n")
            filter_args = filter_definitions.map { |f| "    #{f[:key]}: $#{f[:key]}" }.join("\n")

            <<~GRAPHQL
              query #{QUERY_NAMES.fetch(projection)}(
                $fullPath: ID!
                $sort: WorkItemSort
              #{filter_vars}
                $includeDescendants: Boolean
                $excludeProjects: Boolean
                $excludeGroupWorkItems: Boolean
                $afterCursor: String
                $firstPageSize: Int
              ) {
                namespace(fullPath: $fullPath) {
                  id
                  name
                  workItems(
                    sort: $sort
              #{filter_args}
                    includeDescendants: $includeDescendants
                    excludeProjects: $excludeProjects
                    excludeGroupWorkItems: $excludeGroupWorkItems
                    after: $afterCursor
                    first: $firstPageSize
                  ) {
                    pageInfo {
                      hasNextPage
                      hasPreviousPage
                      startCursor
                      endCursor
                    }
                    nodes {
              #{node_selection(projection)}
                    }
                  }
                }
              }
            GRAPHQL
          end

          # Returns [variables, unsupported_filter_keys]: filters whose key is
          # not in filter_definitions are reported back, not silently dropped.
          def build_variables(full_path:, filters:, sort: nil, first: nil, after: nil)
            variables = { fullPath: full_path }

            filter_mapping = filter_definitions.index_by { |f| f[:key] }

            # fullPath overrides the top-level namespace scope rather than
            # being a workItems argument, so handle it separately.
            if filters['fullPath'].present?
              variables[:fullPath] = filters['fullPath']
              filters = filters.except('fullPath')
            end

            filter_mapping.each do |filter_key, definition|
              value = filters[filter_key]
              next if value.nil?

              variable_key = filter_key.to_sym

              if COMPOSITE_FILTERS.include?(filter_key)
                variables[variable_key] = apply_nested_transforms(value, filter_mapping)
              else
                transform = definition[:transform]
                variables[variable_key] = transform ? transform.call(value) : value
              end
            end

            unsupported_filters = filters.keys.select do |key|
              !filter_mapping.key?(key) && filters[key].present?
            end

            variables[:sort] = sort if sort.present?

            # Hierarchy scoping defaults
            variables[:includeDescendants] = true
            variables[:excludeProjects] = false
            variables[:excludeGroupWorkItems] = false

            variables[:firstPageSize] = first || DEFAULT_PAGE_SIZE
            variables[:afterCursor] = after if after

            [variables.compact, unsupported_filters]
          end

          private

          def node_selection(projection)
            projection == :compact ? compact_node_selection : full_node_selection
          end

          def compact_node_selection
            <<~GRAPHQL.indent(8).chomp
              id
              iid
              title
              state
              webUrl
              reference(full: true)
              createdAt
              updatedAt
              workItemType {
                id
                name
              }
            GRAPHQL
          end

          def full_node_selection
            <<~GRAPHQL.indent(8).chomp
              id
              iid
              title
              state
              confidential
              createdAt
              updatedAt
              closedAt
              webUrl
              reference(full: true)
              author {
                id
                name
                username
                webUrl
              }
              namespace {
                id
                fullPath
              }
              workItemType {
                id
                name
                iconName
              }
              widgets {
                type
              #{widget_fragments.join("\n")}
              }
            GRAPHQL
          end

          def apply_nested_transforms(nested_filters, filter_mapping)
            nested_filters.each_with_object({}) do |(key, value), result|
              transform = filter_mapping[key]&.dig(:transform)
              result[key] = if transform && value.is_a?(Array)
                              value.map { |v| transform.call(v) }
                            elsif transform
                              transform.call(value)
                            else
                              value
                            end
            end
          end
        end
      end
    end
  end
end

Mcp::Tools::WorkItems::WorkItemsQueryBuilder.prepend_mod
