# frozen_string_literal: true

module Gitlab
  module Mcp
    # Name and version that an MCP client reports about itself. Both values are client-supplied,
    # so only these two are kept, and each is sanitized and truncated.
    class ClientInfo
      # Key under which the stateless revision sends `clientInfo` in every request's `_meta`.
      # See: https://modelcontextprotocol.io/specification/2026-07-28/basic/versioning
      META_KEY = 'io.modelcontextprotocol/clientInfo'

      # Client-supplied, so capped to keep log lines and event properties small.
      MAX_LENGTH = 64

      # First product token of a User-Agent, for example `Cursor/1.0.0` or `node`.
      USER_AGENT_PRODUCT = %r{\A(?<name>[!-.0-~]+)(?:/(?<version>[!-~]+))?}

      attr_reader :name, :version

      class << self
        # Resolves the client from sources that every request can carry, so `initialize` and
        # `tools/call` from the same client get the same value. A handshake-revision client sends
        # `clientInfo` only on `initialize`, so that value is read separately by {.declared}.
        #
        # @param rpc_params [Hash, Array, nil] the JSON-RPC `params` of the request
        # @param user_agent [String, nil] the `User-Agent` request header
        # @return [Gitlab::Mcp::ClientInfo, nil] nil when neither source has a usable client name
        def from_request(rpc_params, user_agent:)
          from_declared(meta_client_info(rpc_params)) || from_user_agent(user_agent)
        end

        # The `clientInfo` that the `initialize` request declares.
        #
        # @param rpc_params [Hash, Array, nil] the JSON-RPC `params` of the request
        # @return [Gitlab::Mcp::ClientInfo, nil] nil when `clientInfo` has no usable name
        def declared(rpc_params)
          return unless rpc_params.is_a?(Hash)

          from_declared(rpc_params.with_indifferent_access[:clientInfo])
        end

        private

        def meta_client_info(rpc_params)
          return unless rpc_params.is_a?(Hash)

          meta = rpc_params.with_indifferent_access[:_meta]
          meta[META_KEY] if meta.is_a?(Hash)
        end

        def from_declared(client_info)
          return unless client_info.is_a?(Hash)

          build(client_info[:name], client_info[:version])
        end

        def from_user_agent(user_agent)
          return unless user_agent.is_a?(String)

          match = USER_AGENT_PRODUCT.match(user_agent.dup.force_encoding(Encoding::UTF_8).scrub('').strip)
          return unless match

          build(match[:name], match[:version])
        end

        def build(name, version)
          name = sanitize(name)
          return unless name

          new(name: name, version: sanitize(version))
        end

        def sanitize(value)
          return unless value.is_a?(String)

          value.dup.force_encoding(Encoding::UTF_8).scrub('').gsub(/[[:cntrl:]]/, '').strip[0, MAX_LENGTH].presence
        end
      end

      def initialize(name:, version: nil)
        @name = name
        @version = version
      end

      # Prefixed with `mcp_` because `client_name` is the allowlisted {Gitlab::Tracking::ClientIdentity} slug.
      #
      # @return [Hash] `mcp_client_name` and `mcp_client_version`, without nil values
      def to_h
        { mcp_client_name: name, mcp_client_version: version }.compact
      end
    end
  end
end
