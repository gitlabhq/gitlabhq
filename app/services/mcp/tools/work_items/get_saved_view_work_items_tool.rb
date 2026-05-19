# frozen_string_literal: true

module Mcp
  module Tools
    module WorkItems
      class GetSavedViewWorkItemsTool < BaseTool
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

          def build_query
            filter_vars = filter_definitions.map { |f| "  $#{f[:key]}: #{f[:type]}" }.join("\n")
            filter_args = filter_definitions.map { |f| "    #{f[:key]}: $#{f[:key]}" }.join("\n")
            widget_fragments_str = widget_fragments.join("\n")

            <<~GRAPHQL
              query GetWorkItemsFull(
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
              #{widget_fragments_str}
                      }
                    }
                  }
                }
              }
            GRAPHQL
          end
        end

        register_version VERSIONS[:v0_1_0], {
          operation_name: 'namespace',
          # Lambda defers build_query evaluation until after prepend_mod
          # applies the EE module, so EE filter_definitions and
          # widget_fragments are included in the composed GraphQL query.
          graphql_operation: -> { build_query }
        }

        attr_reader :unsupported_filters

        COMPOSITE_FILTERS = %w[not or].freeze

        def initialize(current_user:, params:, version: nil)
          super
          @unsupported_filters = []
        end

        def build_variables
          parent_info = resolve_parent
          filters = (params[:filters] || {}).stringify_keys

          build_work_items_variables(parent_info[:full_path], filters, params[:sort])
        end

        protected

        def build_variables_0_1_0
          build_variables
        end

        private

        def process_result(result)
          processed = super
          return processed if processed[:isError]

          work_items_data = processed[:structuredContent]['workItems']
          return ::Mcp::Tools::Response.error("The work items are inaccessible") unless work_items_data

          formatted_content = [{ type: 'text', text: Gitlab::Json.dump(work_items_data) }]
          ::Mcp::Tools::Response.success(formatted_content, work_items_data)
        end

        def build_work_items_variables(full_path, filters, sort)
          variables = { fullPath: full_path }

          filter_mapping = self.class.filter_definitions.index_by { |f| f[:key] }

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

          # Detect filters present in the saved view but not supported by this tool
          @unsupported_filters = filters.keys.select do |key|
            !filter_mapping.key?(key) && filters[key].present?
          end

          variables[:sort] = sort if sort.present?

          # Hierarchy scoping defaults
          variables[:includeDescendants] = true
          variables[:excludeProjects] = false
          variables[:excludeGroupWorkItems] = false

          # Apply pagination from params
          variables[:firstPageSize] = params[:first] || 20
          variables[:afterCursor] = params[:after] if params[:after]

          variables.compact
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

Mcp::Tools::WorkItems::GetSavedViewWorkItemsTool.prepend_mod
