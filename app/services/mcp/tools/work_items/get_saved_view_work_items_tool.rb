# frozen_string_literal: true

module Mcp
  module Tools
    module WorkItems
      class GetSavedViewWorkItemsTool < BaseTool
        class << self
          def build_query
            <<~GRAPHQL
              query GetWorkItemsFull(
                $fullPath: ID!
                $sort: WorkItemSort
                $state: IssuableState
                $search: String
                $in: [IssuableSearchableField!]
                $assigneeWildcardId: AssigneeWildcardId
                $assigneeUsernames: [String!]
                $authorUsername: String
                $confidential: Boolean
                $labelName: [String!]
                $milestoneTitle: [String!]
                $milestoneWildcardId: MilestoneWildcardId
                $myReactionEmoji: String
                $types: [IssueType!]
                $not: NegatedWorkItemFilterInput
                $or: UnionedWorkItemFilterInput
                $hierarchyFilters: HierarchyFilterInput
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
                    state: $state
                    search: $search
                    in: $in
                    assigneeUsernames: $assigneeUsernames
                    assigneeWildcardId: $assigneeWildcardId
                    authorUsername: $authorUsername
                    confidential: $confidential
                    labelName: $labelName
                    milestoneTitle: $milestoneTitle
                    milestoneWildcardId: $milestoneWildcardId
                    myReactionEmoji: $myReactionEmoji
                    types: $types
                    not: $not
                    or: $or
                    hierarchyFilters: $hierarchyFilters
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
                        ... on WorkItemWidgetMilestone {
                          milestone {
                            id
                            title
                            dueDate
                            startDate
                          }
                        }
                        ... on WorkItemWidgetStartAndDueDate {
                          dueDate
                          startDate
                        }
                        ... on WorkItemWidgetHierarchy {
                          parent {
                            id
                          }
                        }
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
          graphql_operation: build_query
        }

        attr_reader :unsupported_filters

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

          # Map saved view filters to GraphQL variables
          filter_mapping = {
            'assigneeUsernames' => :assigneeUsernames,
            'assigneeWildcardId' => :assigneeWildcardId,
            'authorUsername' => :authorUsername,
            'labelName' => :labelName,
            'milestoneTitle' => :milestoneTitle,
            'milestoneWildcardId' => :milestoneWildcardId,
            'myReactionEmoji' => :myReactionEmoji,
            'confidential' => :confidential,
            'types' => :types,
            'state' => :state,
            'search' => :search,
            'in' => :in,
            'hierarchyFilters' => :hierarchyFilters,
            'not' => :not,
            'or' => :or
          }

          # fullPath overrides the top-level namespace scope rather than
          # being a workItems argument, so handle it separately.
          if filters['fullPath'].present?
            variables[:fullPath] = filters['fullPath']
            filters = filters.except('fullPath')
          end

          filter_mapping.each do |filter_key, variable_key|
            value = filters[filter_key]
            variables[variable_key] = value unless value.nil?
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
      end
    end
  end
end
