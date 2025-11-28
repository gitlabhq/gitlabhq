# frozen_string_literal: true

module Mcp
  module Tools
    module WorkItems
      class BaseTool < Mcp::Tools::GraphqlTool
        include Mcp::Tools::Concerns::Constants
        include Mcp::Tools::Concerns::ResourceFinder
        include Mcp::Tools::Concerns::UrlParser

        protected

        # Returns: { type: :project/:group, full_path: String, record: Project/Group }
        def resolve_parent
          @resolved_parent ||= params[:url] ? resolve_parent_from_url(params[:url]) : resolve_parent_from_id
        end

        # Returns: Work item global ID as String (e.g., "gid://gitlab/WorkItem/123")
        def resolve_work_item_id
          @resolved_work_item_id ||= if params[:url]
                                       resolve_work_item_from_url(params[:url])
                                     else
                                       resolve_work_item_from_params
                                     end
        end

        def validate_no_quick_actions!(text, field_name: 'text')
          return unless text&.match?(URL_PATTERNS[:quick_action])

          raise ArgumentError, "Quick actions (commands starting with /) are not allowed in #{field_name}"
        end

        private

        def resolve_parent_from_id
          identifier = params[:project_id] || params[:group_id]
          parent_type = params[:project_id] ? :project : :group

          raise ArgumentError, 'Must provide either project_id or group_id' unless identifier

          parent = find_parent_by_id_or_path(parent_type, identifier)

          { type: parent_type, full_path: parent.full_path, record: parent }
        end

        def resolve_work_item_from_params
          iid = params[:work_item_iid]
          raise ArgumentError, 'Must provide work_item_iid' unless iid

          parent_info = resolve_parent
          work_item = find_work_item_in_parent(parent_info[:record], iid)

          work_item.to_global_id.to_s
        end
      end
    end
  end
end
