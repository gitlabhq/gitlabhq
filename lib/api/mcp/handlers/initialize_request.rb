# frozen_string_literal: true

module API
  module Mcp
    module Handlers
      # See: https://modelcontextprotocol.io/specification/2025-06-18/schema#initializerequest
      class InitializeRequest < Base
        # Revisions that keep the `initialize` handshake.
        # See: https://modelcontextprotocol.io/specification/2026-07-28/basic/versioning#terminology
        HANDSHAKE_PROTOCOL_VERSIONS = %w[
          2025-11-25
          2025-06-18
          2025-03-26
        ].freeze

        # The newest revision that still negotiates via handshake, not the stateless variant.
        # Its own constant, so the fallback doesn't depend on HANDSHAKE_PROTOCOL_VERSIONS order.
        LATEST_HANDSHAKE_PROTOCOL_VERSION = '2025-11-25'

        # Revisions that replace the handshake with per-request metadata
        STATELESS_PROTOCOL_VERSIONS = %w[
          2026-07-28
        ].freeze

        SUPPORTED_PROTOCOL_VERSIONS = (STATELESS_PROTOCOL_VERSIONS + HANDSHAKE_PROTOCOL_VERSIONS).freeze

        def invoke
          client_version = params[:protocolVersion]

          if client_version.nil?
            raise ArgumentError, "Missing required parameter 'protocolVersion'. " \
              "Supported: #{SUPPORTED_PROTOCOL_VERSIONS.join(', ')}"
          end

          unless SUPPORTED_PROTOCOL_VERSIONS.include?(client_version)
            raise ArgumentError, "Unsupported protocol version '#{client_version}'. " \
              "Supported: #{SUPPORTED_PROTOCOL_VERSIONS.join(', ')}"
          end

          {
            protocolVersion: negotiated_protocol_version(client_version),
            capabilities: {
              tools: { listChanged: false }
            },
            serverInfo: {
              name: 'Official GitLab MCP Server',
              version: Gitlab::VERSION
            }
          }
        end

        private

        # A stateless revision has no `initialize` handshake, so a client that reaches this
        # handler is speaking a handshake revision even when it asks for a newer one. Answering
        # with the newest handshake revision keeps such clients connected without claiming
        # semantics this server does not implement.
        # See: https://modelcontextprotocol.io/specification/2026-07-28/basic/versioning#backward-compatibility-with-initialization-based-versions
        def negotiated_protocol_version(client_version)
          return client_version if HANDSHAKE_PROTOCOL_VERSIONS.include?(client_version)

          LATEST_HANDSHAKE_PROTOCOL_VERSION
        end
      end
    end
  end
end
