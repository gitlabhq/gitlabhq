# frozen_string_literal: true

module Mcp
  module Tools
    module WorkItems
      class LinkWorkItemsTool < BaseTool
        register_version VERSIONS[:v0_1_0], {
          operation_name: 'workItemAddLinkedItems',
          graphql_operation: load_graphql('work_items/link_work_items.mutation.graphql')
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
          Array(params[:work_items_ids]).map do |id|
            next id if id.is_a?(String) && id.start_with?('gid://gitlab/WorkItem/')

            resolve_target_iid(id)
          end
        end

        # Plain iids resolve in the source work item's project or group, matching
        # how agents already identify the source; cross-parent targets need a GID.
        def resolve_target_iid(value)
          unless value.to_s.match?(/\A\d+\z/)
            raise ArgumentError,
              "Invalid target work item ID format: '#{value}'. Expected an iid (integer) " \
                'or a global ID (gid://gitlab/WorkItem/<id>)'
          end

          parent_info = resolve_parent
          work_item =
            begin
              find_work_item_in_parent!(parent_info[:record], value)
            rescue ArgumentError
              raise ArgumentError,
                "Target work item with iid '#{value}' not found in #{parent_info[:full_path]}. " \
                  'Use a global ID (gid://gitlab/WorkItem/<id>) for work items in other projects or groups.'
            end

          work_item.to_global_id.to_s
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
