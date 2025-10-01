# frozen_string_literal: true

module API
  module Mcp
    class Base < ::API::Base
      include ::API::Helpers::HeadersHelpers
      include APIGuard

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
        }
        # NOTE: Parse error	code -32700	is unsupported due to 400 Bad Request returned by Workhorse
      }.freeze

      # JSON-RPC Supported Requests
      # See: https://modelcontextprotocol.io/specification/2025-06-18/schema#common-types
      JSONRPC_METHOD_HANDLERS = {
        'initialize' => Handlers::InitializeRequest,
        'notifications/initialized' => Handlers::InitializedNotificationRequest,
        'tools/list' => Handlers::ListToolsRequest,
        'tools/call' => Handlers::CallToolRequest
      }.freeze

      feature_category :mcp_server
      allow_access_with_scope :mcp
      urgency :low

      before do
        authenticate!

        not_found! unless Feature.enabled?(:mcp_server, current_user) &&
          ::Gitlab::CurrentSettings.instance_level_ai_beta_features_enabled?

        forbidden! unless access_token&.scopes&.map(&:to_s) == [Gitlab::Auth::MCP_SCOPE.to_s]
      end

      helpers do
        def invoke_basic_handler
          method_name = params[:method]
          handler_class = JSONRPC_METHOD_HANDLERS[method_name] || method_not_found!(method_name)
          handler = handler_class.new(params[:params] || {}, oauth_access_token, current_user)
          handler.invoke
        end

        def find_handler_class(method_name)
          JSONRPC_METHOD_HANDLERS[method_name] || method_not_found!(method_name)
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

        def create_handler(handler_class, handler_params)
          handler_class.new(handler_params, oauth_access_token, current_user)
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
          requires :jsonrpc, type: String, allow_blank: false, values: [JSONRPC_VERSION]
          requires :method, type: String, allow_blank: false
          optional :id, allow_blank: false # NOTE: JSON-RPC server must reply with same value and type for "id" member
          optional :params, types: [Hash, Array]
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
        post do
          status :ok

          result =
            if Feature.enabled?(:mcp_server_new_implementation, current_user)
              case params[:method]
              when 'tools/call'
                Handlers::CallTool.new(namespace_setting(:mcp_manager)).invoke(request, params[:params], current_user)
              when 'tools/list'
                Handlers::ListTools.new(namespace_setting(:mcp_manager)).invoke
              else
                invoke_basic_handler
              end
            else
              handler_class = find_handler_class(params[:method])
              handler = create_handler(handler_class, params[:params] || {})
              handler.invoke
            end

          format_jsonrpc_response(result)
        end

        # See: https://modelcontextprotocol.io/specification/2025-06-18/basic/transports#listening-for-messages-from-the-server
        get do
          status :not_implemented
        end
      end
    end
  end
end
