# frozen_string_literal: true

module Mcp
  module Tools
    module WorkItems
      module SaveWorkItemCommon
        private

        def ensure_single_parent_identifier!
          given = [:url, :project_id, :group_id].select { |key| params[key].present? }
          return if given.length <= 1

          raise ArgumentError, "Provide exactly one of url, project_id, or group_id (got #{given.join(', ')})"
        end

        def normalize_gid(value, model)
          value.to_s.start_with?('gid://') ? value.to_s : "gid://gitlab/#{model}/#{value}"
        end

        def normalize_gids(values, model)
          Array(values).map { |value| normalize_gid(value, model) }
        end

        def description_widget
          return unless params.key?(:description)

          validate_no_quick_actions!(params[:description], field_name: 'description')

          { description: params[:description] }
        end

        def assignees_widget
          return unless params.key?(:assignee_ids)

          { assigneeIds: normalize_gids(params[:assignee_ids], 'User') }
        end

        def start_and_due_date_widget
          {
            startDate: params[:start_date],
            dueDate: params[:due_date],
            isFixed: params[:is_fixed]
          }.compact.presence
        end

        def hierarchy_widget
          return unless params.key?(:parent_id)

          { parentId: normalize_gid(params[:parent_id], 'WorkItem') }
        end

        def health_status_widget
          return unless params.key?(:health_status)

          { healthStatus: params[:health_status] }
        end

        def status_widget
          return unless params.key?(:status_id)

          { status: params[:status_id] }
        end

        def agent_plan_widget
          return unless params.key?(:agent_plan)

          { content: params[:agent_plan] }
        end

        def process_result(result)
          processed = super
          return processed if processed[:isError]

          work_item = processed[:structuredContent]['workItem']
          return ::Mcp::Tools::Base::Response.error('Operation returned no data') unless work_item

          formatted = format_work_item(work_item)
          formatted_content = [{ type: 'text', text: Gitlab::Json.dump(formatted) }]

          ::Mcp::Tools::Base::Response.success(formatted_content, formatted)
        end

        def format_work_item(work_item)
          {
            'id' => work_item['id'],
            'iid' => work_item['iid'],
            'type' => work_item.dig('workItemType', 'name'),
            'title' => work_item['title'],
            'state' => work_item['state'],
            'confidential' => work_item['confidential'],
            'web_url' => work_item['webUrl']
          }
        end
      end
    end
  end
end
