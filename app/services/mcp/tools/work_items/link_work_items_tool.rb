# frozen_string_literal: true

module Mcp
  module Tools
    module WorkItems
      class LinkWorkItemsTool < BaseTool
        class << self
          def build_mutation
            <<~GRAPHQL
              mutation LinkWorkItems($input: WorkItemAddLinkedItemsInput!) {
                workItemAddLinkedItems(input: $input) {
                  workItem {
                    id
                    iid
                    title
                  }
                  message
                  errors
                }
              }
            GRAPHQL
          end
        end

        register_version VERSIONS[:v0_1_0], {
          operation_name: 'workItemAddLinkedItems',
          graphql_operation: build_mutation
        }

        def build_variables
          source_id = resolve_work_item_id
          target_ids = resolve_target_work_item_ids

          {
            input: {
              id: source_id,
              workItemsIds: target_ids,
              linkType: normalized_link_type
            }.compact
          }
        end

        private

        def resolve_target_work_item_ids
          ids = Array(params[:work_items_ids])

          ids.map do |id|
            unless id.is_a?(String) && id.start_with?('gid://gitlab/WorkItem/')
              raise ArgumentError,
                "Invalid work item ID format: '#{id}'. Expected GitLab global ID (gid://gitlab/WorkItem/<id>)"
            end

            id
          end
        end

        def normalized_link_type
          link_type = params[:link_type].to_s.downcase
          return 'RELATED' if link_type.blank? || link_type == 'relates_to'

          raise ArgumentError,
            "Invalid link_type: '#{params[:link_type]}'"
        end
      end
    end
  end
end

Mcp::Tools::WorkItems::LinkWorkItemsTool.prepend_mod
