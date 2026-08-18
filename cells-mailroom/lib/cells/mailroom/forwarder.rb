# frozen_string_literal: true

require 'faraday'
require 'jwt'
require 'openssl'
require 'securerandom'
require 'labkit/fields'

module Cells
  module Mailroom
    # Forwards a raw email payload directly to a cell's internal mail_room
    # endpoint. The cell is resolved up front by the Topology Service
    # (see CellRouter), so forwarding is a single, uniform operation regardless
    # of how the email was identified.
    class Forwarder
      INTERNAL_API_REQUEST_HEADER = 'Gitlab-Mailroom-Api-Request'
      JWT_ISSUER = 'gitlab-mailroom'
      # We sign with an asymmetric key (ES256) so a compromised cell cannot forge
      # tokens for other cells: cells only hold the public key. See
      # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/242985.
      JWT_ALGORITHM = 'ES256'
      # Short-lived tokens: a request is signed immediately before it is sent, so
      # a minute is plenty and it bounds the replay window if a token is
      # intercepted. The verifier also enforces its own iat window.
      JWT_EXPIRY_SECONDS = 60
      INTERNAL_API_PATH = '/api/v4/internal/mail_room'
      DEFAULT_SCHEME = 'https'
      OPEN_TIMEOUT_SECONDS = 5
      TIMEOUT_SECONDS = 30

      # @param mailbox_type [String] "incoming_email" or "service_desk_email"
      # @param signing_key_path [String] path to the PEM-encoded EC private key
      #   used to sign forwarded requests. The matching public key is configured
      #   on each cell so it can verify the signature.
      # @param scheme [String] URL scheme used to reach cells ("https" in
      #   production, "http" for local environments). Cell addresses are bare
      #   hosts, so the scheme is chosen here rather than carried in the address.
      # @param logger [#info, #warn]
      def initialize(mailbox_type:, signing_key_path:, scheme: DEFAULT_SCHEME, logger:)
        @mailbox_type = mailbox_type
        @signing_key_path = signing_key_path
        @scheme = scheme
        @logger = logger
      end

      # Forwards the raw email to the given cell.
      #
      # The cell address returned by the Topology Service Classify RPC is a bare
      # host authority (host[:port]), not a URL: the Topology Service `address`
      # is configured as a host and the HTTP Router treats it the same way (it
      # only sets `url.host`). We build the target URL by combining our scheme,
      # that host, and the fixed internal mail_room path.
      #
      # @param raw [String] the raw RFC822 email
      # @param cell_address [String] the cell host authority (host[:port])
      # @return [Boolean] whether the cell accepted the email
      def forward(raw, cell_address)
        url = endpoint_url(cell_address)

        response = connection.post(url, raw) do |request|
          request.headers['Content-Type'] = 'text/plain'
          request.headers[INTERNAL_API_REQUEST_HEADER] = jwt_token
        end

        logger.info(
          Labkit::Fields::LOG_MESSAGE => 'Email forwarded',
          Labkit::Fields::HTTP_URL => url,
          Labkit::Fields::HTTP_STATUS_CODE => response.status
        )
        response.success?
      rescue StandardError => e
        logger.warn(
          Labkit::Fields::LOG_MESSAGE => 'Email forwarding failed',
          Labkit::Fields::HTTP_URL => url,
          Labkit::Fields::ERROR_MESSAGE => e.message
        )
        false
      end

      private

      attr_reader :mailbox_type, :signing_key_path, :scheme, :logger

      def endpoint_url(cell_address)
        "#{scheme}://#{cell_address}#{INTERNAL_API_PATH}/#{mailbox_type}"
      end

      def connection
        @connection ||= Faraday.new do |f|
          f.options.open_timeout = OPEN_TIMEOUT_SECONDS
          f.options.timeout = TIMEOUT_SECONDS
        end
      end

      def jwt_token
        now = Time.now.to_i
        payload = {
          nonce: SecureRandom.hex(12),
          iat: now,
          exp: now + JWT_EXPIRY_SECONDS,
          iss: JWT_ISSUER
        }
        # The `kid` is the key's RFC 7638 thumbprint. The cell selects the
        # matching public key from its configured set by this `kid`, which is
        # what lets public keys be rotated without a hard cutover.
        ::JWT.encode(payload, signing_key, JWT_ALGORITHM, { kid: signing_key_kid })
      end

      def signing_key
        @signing_key ||= OpenSSL::PKey::EC.new(File.read(signing_key_path))
      end

      def signing_key_kid
        @signing_key_kid ||= ::JWT::JWK.new(signing_key).export[:kid]
      end
    end
  end
end
