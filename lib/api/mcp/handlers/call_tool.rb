# frozen_string_literal: true

module API
  module Mcp
    module Handlers
      class CallTool
        def initialize(manager)
          @manager = manager
        end

        def invoke(request, params, current_user = nil)
          tool_name = params[:name]
          session_id = request[:id] || SecureRandom.uuid

          track_start_event(tool_name, session_id, current_user)

          tool = fetch_tool(tool_name, session_id, current_user)
          configure_tool_credentials(tool, current_user)
          execute_tool_with_tracking(tool, request, params, tool_name, session_id, current_user)
        end

        private

        attr_reader :manager

        def fetch_tool(tool_name, session_id, current_user)
          manager.get_tool(name: tool_name)
        rescue ::Mcp::Tools::Manager::ToolNotFoundError => e
          track_finish_event(tool_name, session_id, current_user, success: false, error: e)
          raise ArgumentError, e.message
        end

        def configure_tool_credentials(tool, current_user)
          tool.set_cred(current_user: current_user) if tool.is_a?(::Mcp::Tools::CustomService)
        end

        def execute_tool_with_tracking(tool, request, params, tool_name, session_id, current_user)
          result = tool.execute(request: request, params: params)
          track_finish_event(tool_name, session_id, current_user, success: true)
          result
        rescue StandardError => error
          track_finish_event(tool_name, session_id, current_user, success: false, error: error)
          raise error
        end

        # Stub methods for CE - will be overridden in EE
        def track_start_event(tool_name, session_id, current_user)
          # No-op in CE
        end

        def track_finish_event(tool_name, session_id, current_user, success:, error: nil)
          # No-op in CE
        end
      end
    end
  end
end

API::Mcp::Handlers::CallTool.prepend_mod
