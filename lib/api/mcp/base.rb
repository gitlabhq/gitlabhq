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
        not_found! unless Feature.enabled?(:mcp_server, current_user)
      end

      # Model Context Protocol (MCP) specification
      # See: https://modelcontextprotocol.io/specification/2025-06-18
      namespace :mcp do
        params do
          # JSON-RPC Request Object
          # See: https://www.jsonrpc.org/specification#request_object
          requires :jsonrpc, type: String, allow_blank: false, values: [JSONRPC_VERSION]
          requires :method, type: String, allow_blank: false
          optional :id, allow_blank: false # NOTE: JSON-RPC server must reply with same value and type for "id" member
          optional :params, types: [Hash, Array]
        end

        rescue_from Grape::Exceptions::ValidationErrors do |e|
          error!({
            jsonrpc: JSONRPC_VERSION,
            error: JSONRPC_ERRORS[:invalid_request].merge({ data: { validations: e.full_messages } }),
            id: nil
          }, 400)
        end

        rescue_from ArgumentError do |e|
          error!({
            jsonrpc: JSONRPC_VERSION,
            error: JSONRPC_ERRORS[:invalid_params].merge({ data: { params: e.message } }),
            id: nil
          }, 400)
        end

        # See: https://modelcontextprotocol.io/specification/2025-06-18/basic/transports#sending-messages-to-the-server
        post do
          status 200

          handler_class = JSONRPC_METHOD_HANDLERS[params[:method]]
          unless handler_class
            error!({
              jsonrpc: JSONRPC_VERSION,
              error: JSONRPC_ERRORS[:method_not_found].merge({ data: { method: params[:method] } }),
              id: params[:id]
            }, 404)
          end

          result = handler_class.new(params[:params] || {}).invoke

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

        # See: https://modelcontextprotocol.io/specification/2025-06-18/basic/transports#listening-for-messages-from-the-server
        get do
          status :not_implemented
        end
      end
    end
  end
end
