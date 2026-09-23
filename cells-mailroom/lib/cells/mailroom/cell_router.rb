# frozen_string_literal: true

require 'gitlab/cells/topology_service'
require 'labkit/fields'

module Cells
  module Mailroom
    # Resolves an identified Target to the address of the cell that owns it,
    # using the Topology Service Classify RPC.
    #
    # Every incoming email is routed the same way: the gem identifies it as a
    # Target (project id, namespace id, route, or service desk custom email) and
    # this resolves the Target to a cell. Classify is available to a regular
    # cell identity, so this needs no admin privileges.
    class CellRouter
      TopologyService = Gitlab::Cells::TopologyService
      Claim = TopologyService::Types::V1::Claim

      UnsupportedTargetError = Class.new(StandardError)

      # Maps a Target#kind to the Topology Service Claim field that carries it.
      CLAIM_FIELDS = {
        project_id: :project_id,
        namespace_id: :namespace_id,
        route: :route,
        service_desk_custom_email: :service_desk_custom_email,
        service_desk_project_key_address_slug: :service_desk_project_key_address_slug
      }.freeze

      # @param stub [Gitlab::Cells::TopologyService::ClassifyService::Stub]
      #   A configured gRPC stub. Injected so this is easy to stub in tests.
      # @param logger [#info, #warn]
      def initialize(stub:, logger:)
        @stub = stub
        @logger = logger
      end

      # Resolves a Target to the owning cell's address.
      #
      # @param target [Gitlab::EmailHandler::Target, nil]
      # @return [String, nil] the cell address (host:port), or nil if the target
      #   is unknown to the Topology Service
      def address_for(target)
        return unless target

        classify(classify_request(target), target_kind: target.kind)
      end

      # Resolves the address of the default (first) cell, used to route emails
      # that cannot be identified. This mirrors the HTTP Router's FIRST_CELL
      # classification: the Topology Service returns the address of the cell it
      # is configured to treat as the default, using the same regular cell
      # identity (no admin privileges).
      #
      # @return [String, nil] the default cell address (host:port), or nil if
      #   the Topology Service cannot provide one
      def default_cell_address
        request = TopologyService::ClassifyRequest.new(type: TopologyService::ClassifyType::FIRST_CELL)
        classify(request, target_kind: :first_cell)
      end

      private

      attr_reader :stub, :logger

      def classify(request, target_kind:)
        response = stub.classify(request)
        usable_address(response&.proxy&.address, target_kind: target_kind)
      rescue GRPC::NotFound
        nil
      rescue GRPC::BadStatus => e
        logger.warn(
          Labkit::Fields::LOG_MESSAGE => "Topology Service classify failed for #{target_kind}",
          Labkit::Fields::ERROR_MESSAGE => e.message
        )
        nil
      end

      # Treats an address we cannot turn into a URL authority as unresolved, so
      # the caller falls back to the default cell rather than forwarding to a
      # nonsense host. GitLab Shell's resolver rejects the same shapes.
      def usable_address(address, target_kind:)
        return if address.nil? || address.empty?
        return address if bare_host?(address)

        logger.warn(
          Labkit::Fields::LOG_MESSAGE => "Topology Service returned an unusable cell address for #{target_kind}",
          Labkit::Fields::TCP_ADDRESS => address
        )
        nil
      end

      # True for a hostname or IPv4 address, optionally with a port. Cells are
      # never addressed by IPv6, so a colon left after stripping the port means
      # the address is not something we can use.
      def bare_host?(address)
        return false if address.include?('/')

        host = address.include?(':') ? address.rpartition(':').first : address
        !host.empty? && !host.include?(':')
      end

      def classify_request(target)
        field = CLAIM_FIELDS.fetch(target.kind) do
          raise UnsupportedTargetError, "unsupported target kind: #{target.kind}"
        end

        TopologyService::ClassifyRequest.new(claims: [Claim.new(field => target.value)])
      end
    end
  end
end
