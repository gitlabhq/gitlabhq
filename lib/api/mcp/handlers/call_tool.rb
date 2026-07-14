# frozen_string_literal: true

module API
  module Mcp
    module Handlers
      class CallTool
        def initialize(manager)
          @manager = manager
        end

        def invoke(request, params, current_user = nil, tool_name_prefix: nil)
          tool_name = params[:name]
          tool_name.delete_prefix!(tool_name_prefix) if tool_name_prefix.present?
          session_id = request[:id] || SecureRandom.uuid

          track_start_event(tool_name, session_id, current_user, params: params)

          tool = fetch_tool(tool_name, session_id, current_user, params)
          configure_tool_credentials(tool, current_user)
          execute_tool_with_tracking(tool, request, params, tool_name, session_id, current_user)
        end

        private

        attr_reader :manager

        def fetch_tool(tool_name, session_id, current_user, params)
          start = current_monotonic_time
          manager.get_tool(name: tool_name)
        rescue ::Mcp::Tools::Manager::ToolNotFoundError => e
          track_finish_event(tool_name, session_id, current_user, success: false, error: e, params: params)
          log_tool_call(tool_name, session_id, current_user, params, error: e, duration_s: duration_since(start))
          raise ArgumentError, e.message
        end

        def configure_tool_credentials(tool, current_user)
          tool.set_cred(current_user: current_user) if tool.is_a?(::Mcp::Tools::Base::CustomService)
          tool.set_cred(current_user: current_user) if tool.is_a?(::Mcp::Tools::Base::GraphqlService)
        end

        def execute_tool_with_tracking(tool, request, params, tool_name, session_id, current_user)
          start = current_monotonic_time
          result = tool.execute(request: request, params: params)
          track_finish_event(tool_name, session_id, current_user, success: true, params: params)
          log_tool_call(tool_name, session_id, current_user, params, duration_s: duration_since(start))
          result
        rescue StandardError => error
          track_finish_event(tool_name, session_id, current_user, success: false, error: error, params: params)
          log_tool_call(tool_name, session_id, current_user, params, error: error, duration_s: duration_since(start))
          raise error
        end

        def log_tool_call(tool_name, session_id, current_user, params, duration_s:, error: nil)
          arguments = params.to_h.with_indifferent_access[:arguments] || {}

          expanded = { arguments: filter_parameters(arguments) }
          error_fields = {}
          if error
            error_fields[::Labkit::Fields::ERROR_TYPE] = error.class.name
            expanded[::Labkit::Fields::ERROR_MESSAGE] = error.message
          end

          logger.conditional_info(
            current_user,
            message: 'MCP tool call',
            event_name: 'tool_call',
            ai_component: 'mcp_server',
            tool_name: tool_name,
            session_id: session_id,
            tool_status: error.nil? ? 'done' : 'fail',
            ::Labkit::Fields::DURATION_S => duration_s,
            argument_keys: arguments.keys,
            namespace: tool_call_namespace(params),
            expanded: expanded,
            **error_fields
          )
        end

        def filter_parameters(arguments)
          ::ActiveSupport::ParameterFilter.new(::API::API::LOG_FILTERS).filter(arguments)
        end

        def logger
          ::Gitlab::Mcp::Logger.build
        end

        def current_monotonic_time
          ::Gitlab::Metrics::System.monotonic_time
        end

        def duration_since(start)
          (current_monotonic_time - start).round(6)
        end

        # Stub methods for CE - will be overridden in EE
        def track_start_event(tool_name, session_id, current_user, params: nil)
          # No-op in CE
        end

        def track_finish_event(tool_name, session_id, current_user, success:, error: nil, params: nil)
          # No-op in CE
        end

        def tool_call_namespace(_params)
          # Resolving a namespace requires EE-only finders, and expanded logging is EE-only.
          nil
        end
      end
    end
  end
end

API::Mcp::Handlers::CallTool.prepend_mod
