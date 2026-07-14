# frozen_string_literal: true

module API
  module Mcp
    class Base < ::API::Base
      include ::API::Helpers::HeadersHelpers
      include APIGuard
      include ::Mcp::Tools::VersionHelper

      helpers ::API::Helpers::Mcp::AuthChallenge

      # JSON-RPC Specification
      # See: https://www.jsonrpc.org/specification
      JSONRPC_VERSION = '2.0'

      # JSON-RPC Error Codes
      # See: https://www.jsonrpc.org/specification#error_object
      JSONRPC_ERRORS = {
        invalid_request: {
          code: -32600,
          message: 'Invalid Request'
        },
        method_not_found: {
          code: -32601,
          message: 'Method not found'
        },
        invalid_params: {
          code: -32602,
          message: 'Invalid params'
        },
        version_mismatch: {
          code: -32001,
          message: 'Version not supported'
        }
        # NOTE: Parse error	code -32700	is unsupported due to 400 Bad Request returned by Workhorse
      }.freeze

      # JSON-RPC Supported Requests
      # See: https://modelcontextprotocol.io/specification/2025-06-18/schema#common-types
      JSONRPC_METHOD_HANDLERS = {
        'initialize' => Handlers::InitializeRequest,
        'notifications/initialized' => Handlers::InitializedNotificationRequest
      }.freeze

      feature_category :mcp_server
      allow_access_with_scope :mcp
      urgency :low

      before do
        authenticate!

        unless feature_available?
          logger.info(
            message: 'MCP server not available',
            event_name: 'permission_denied',
            ai_component: 'mcp_server',
            denial_reason: mcp_denial_reason,
            Labkit::Fields::GL_USER_ID => current_user.id
          )

          not_found!
        end

        forbidden! unless AccessTokenValidationService.new(access_token)
          .include_any_scope?([Gitlab::Auth::MCP_SCOPE, Gitlab::Auth::GRANULAR_SCOPE])
      end

      helpers do
        include ::Gitlab::Utils::StrongMemoize

        def logger
          Gitlab::Mcp::Logger.build
        end
        strong_memoize_attr :logger

        def feature_available?
          mcp_denial_reason.nil?
        end

        def mcp_denial_reason
          # SaaS is short-circuited by the EE override; :instance_setting_disabled is self-managed-only.
          return :instance_setting_disabled unless ::Gitlab::CurrentSettings.mcp_server_enabled?

          nil
        end
        strong_memoize_attr :mcp_denial_reason

        # Returns the allowed MCP tool names for this request, as set by the Duo Workflow
        # executor via the `x-gitlab-enabled-mcp-server-tools` header.
        # Returns nil when the header is absent or blank (no restriction -- all tools allowed).
        def enabled_mcp_server_tools
          header_value = headers['X-Gitlab-Enabled-Mcp-Server-Tools']
          return if header_value.blank?

          header_value.split(',').map(&:strip).reject(&:blank?)
        end

        # Returns the prefix for all MCP tool names for this request.
        # This header can be used by users to prevent tool conflicts when
        # configuring MCP servers of multiple GitLab instances.
        # Return nil when the header is absent or blank (no prefix)
        def mcp_server_tool_name_prefix
          header_value = headers['X-Gitlab-Mcp-Server-Tool-Name-Prefix']
          return if header_value.blank?

          header_value[0, 32]
        end

        def invoke_basic_handler
          method_name = params[:method]
          handler_class = JSONRPC_METHOD_HANDLERS[method_name] || method_not_found!(method_name)
          handler = handler_class.new(params[:params] || {}, oauth_access_token, current_user)
          handler.invoke
        end

        def method_not_found!(method_name)
          # render error used to stop request and return early
          render_structured_api_error!({
            jsonrpc: JSONRPC_VERSION,
            error: JSONRPC_ERRORS[:method_not_found].merge({ data: { method: method_name } }),
            id: params[:id]
          }, 404)
        end

        def oauth_access_token
          token = Doorkeeper::OAuth::Token.from_request(
            current_request,
            *Doorkeeper.configuration.access_token_methods
          )
          unauthorized! unless token
          token
        end

        def format_jsonrpc_response(result)
          if params[:id].nil? || result.nil?
            # JSON-RPC server must not send JSON-RPC response for notifications
            # See: https://modelcontextprotocol.io/specification/2025-06-18/basic/index#notifications
            body false
          else
            {
              jsonrpc: JSONRPC_VERSION,
              result: result,
              id: params[:id]
            }
          end
        end
      end

      # Model Context Protocol (MCP) specification
      # See: https://modelcontextprotocol.io/specification/2025-06-18
      namespace :mcp do
        namespace_setting :mcp_manager, ::Mcp::Tools::Manager.new
        params do
          # JSON-RPC Request Object
          # See: https://www.jsonrpc.org/specification#request_object
          requires :jsonrpc, type: String, desc: 'JSON-RPC protocol version identifier. Must be `2.0`.',
            allow_blank: false, values: [JSONRPC_VERSION]
          requires :method, type: String, desc: 'Name of the JSON-RPC method invoked on the MCP server.',
            allow_blank: false
          optional :id, desc: 'ID of the JSON-RPC request returned in the response.',
            allow_blank: false # NOTE: JSON-RPC server must reply with same value and type for "id" member
          optional :params, desc: 'Object or array that contains parameters passed to the specified JSON-RPC method',
            types: [Hash, Array]
        end

        rescue_from Grape::Exceptions::ValidationErrors do |e|
          render_structured_api_error!({
            jsonrpc: JSONRPC_VERSION,
            error: JSONRPC_ERRORS[:invalid_request].merge({ data: { validations: e.full_messages } }),
            id: nil
          }, 400)
        end

        rescue_from ArgumentError do |e|
          render_structured_api_error!({
            jsonrpc: JSONRPC_VERSION,
            error: JSONRPC_ERRORS[:invalid_params].merge({ data: { params: e.message } }),
            id: nil
          }, 400)
        end

        # See: https://modelcontextprotocol.io/specification/2025-06-18/basic/transports#sending-messages-to-the-server
        desc 'Create MCP request handler' do
          detail 'Handles Model Context Protocol requests'
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags ['mcp']
        end
        route_setting :authorization, permissions: :execute_mcp_tool, boundary_type: :user
        post do
          status :ok

          result =
            case params[:method]
            when 'tools/call'
              Handlers::CallTool.new(namespace_setting(:mcp_manager)).invoke(request, params[:params], current_user,
                tool_name_prefix: mcp_server_tool_name_prefix)
            when 'tools/list'
              Handlers::ListTools.new(namespace_setting(:mcp_manager)).invoke(current_user,
                allowed_tools: enabled_mcp_server_tools, tool_name_prefix: mcp_server_tool_name_prefix)
            else
              invoke_basic_handler
            end

          format_jsonrpc_response(result)
        end

        # See: https://modelcontextprotocol.io/specification/2025-06-18/basic/transports#listening-for-messages-from-the-server
        desc 'Get MCP response listener' do
          detail 'Listens for Model Context Protocol responses'
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' },
            { code: 405, message: 'Method not allowed' }
          ]
          tags ['mcp']
        end
        route_setting :authorization, permissions: :execute_mcp_tool, boundary_type: :user
        get do
          status :method_not_allowed
        end
      end
    end
  end
end

API::Mcp::Base.prepend_mod
