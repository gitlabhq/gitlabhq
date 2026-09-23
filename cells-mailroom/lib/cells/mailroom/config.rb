# frozen_string_literal: true

require 'yaml'
require 'erb'

module Cells
  module Mailroom
    # Reads the bits of config the service needs from the GitLab application's
    # config/gitlab.yml. Keeping configuration in the Rails app (rather than
    # duplicating it here) means the service routes to the same Topology Service
    # and GitLab instance as the rest of the application, and verifies JWTs with
    # the same secret.
    #
    # This mirrors how the GitLab application's own mail_room wrapper
    # (Gitlab::MailRoom) is configured: the gitlab.yml location comes from the
    # MAIL_ROOM_GITLAB_CONFIG_FILE environment variable, defaulting to the
    # application's config/gitlab.yml. No per-setting environment overrides are
    # introduced, so deployment stays consistent with the existing mail_room.
    class Config
      MissingSecretError = Class.new(StandardError)

      # Matches Gitlab::MailRoom's environment variable so both the GitLab
      # application's mail_room and this service can be pointed at the same
      # config file the same way.
      CONFIG_FILE_ENV = 'MAIL_ROOM_GITLAB_CONFIG_FILE'
      DEFAULT_CONFIG_FILE = 'config/gitlab.yml'

      # The GitLab mailbox sections this service can poll, in the order the
      # GitLab application defines them.
      MAILBOX_TYPES = %w[incoming_email service_desk_email].freeze

      # Redis key namespace used by the arbitration lock. Matches the existing
      # GitLab mailroom (Gitlab::Redis::Queues::MAILROOM_NAMESPACE) so this
      # service coordinates against the same lock and never double-processes a
      # message the existing mailroom, or another cells-mailroom pod, has taken.
      ARBITRATION_NAMESPACE = 'mail_room:gitlab'

      # Bind address used when a health check port is configured without an
      # explicit address. Binds all interfaces so a container probe can reach it.
      DEFAULT_HEALTH_CHECK_ADDRESS = '0.0.0.0'

      # Scheme used to reach a cell's internal API when none is configured.
      DEFAULT_CELL_ENDPOINT_SCHEME = 'https'

      def initialize(rails_root:, rails_env: nil)
        @rails_root = rails_root
        @rails_env = rails_env || ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'
      end

      def topology_service_address
        topology_service_config['address']
      end

      def topology_service_tls_enabled?
        topology_service_config.dig('tls', 'enabled') || false
      end

      # Metadata sent with every Topology Service request. We only call the
      # Classify RPC, which is available to a regular cell identity, so we reuse
      # the same metadata the GitLab application uses (read from gitlab.yml). No
      # admin identity is required.
      def topology_service_metadata
        topology_service_config['metadata'] || {}
      end

      def topology_service_certs
        topology_service_config.slice('ca_file', 'certificate_file', 'private_key_file')
      end

      # The GitLab host, used to parse the references message-id fallback when
      # scanning an email for its mail key.
      def gitlab_host
        gitlab_yml.dig('gitlab', 'host')
      end

      # URL scheme used to reach a cell's internal API when forwarding email.
      # Cell addresses returned by the Topology Service are bare hosts, so the
      # scheme is chosen here rather than carried in the address. Configured via
      # `cell.email_forwarding.cell_endpoint.scheme`, defaulting to "https".
      def cell_endpoint_scheme
        cell_endpoint_config['scheme'] || DEFAULT_CELL_ENDPOINT_SCHEME
      end

      # Port of a cell's internal API. When set it replaces any port the
      # Topology Service returns with the cell address, which lets a deployment
      # pin the internal API port independently of what is registered in the
      # Topology Service. This mirrors GitLab Shell, whose Topology Service
      # client takes the same cell_endpoint scheme and port, and whose port
      # likewise always overrides the one returned by the Topology Service.
      # Configured via `cell.email_forwarding.cell_endpoint.port`; when unset
      # the Topology Service address is used as-is.
      #
      # @return [Integer, nil]
      def cell_endpoint_port
        cell_endpoint_config['port']
      end

      # Whether emails that cannot be identified should be routed to the default
      # (first) cell rather than dropped. Configured via
      # `cell.email_forwarding.route_unidentified_to_default_cell` in
      # config/gitlab.yml, defaulting to true.
      #
      # This is needed while incoming email keys can still be unidentifiable
      # offline (for example legacy reply keys without an encoded namespace, or
      # opaque service desk keys whose project_key_address_slug has not been
      # backfilled and claimed yet). Once those are fully claimable in the
      # Topology Service this fallback, and the toggle, can be removed.
      def route_unidentified_to_default_cell?
        value = cell_config.dig('email_forwarding', 'route_unidentified_to_default_cell')
        value.nil? ? true : value
      end

      # Address and port for mail_room's built-in health check server, which
      # serves /liveness. Configured via `cell.email_forwarding.health_check` in
      # config/gitlab.yml; when unset no server is started, so local runs do not
      # bind a port.
      #
      # @return [Hash, nil] `{ address:, port: }`, or nil when not configured
      def health_check_attributes
        settings = cell_config.dig('email_forwarding', 'health_check') || {}
        port = settings['port']
        return unless port

        { address: settings['address'] || DEFAULT_HEALTH_CHECK_ADDRESS, port: port }
      end

      # Path to the PEM-encoded EC private key used to sign requests to the cells'
      # internal mail_room endpoints. This is the signer's key and lives on the
      # service side; each cell holds the matching public key to verify the
      # signature (see Gitlab::MailRoom::Authenticator). Read from
      # `#{mailbox_type}.signing_key_file` in config/gitlab.yml.
      def signing_key_path(mailbox_type)
        gitlab_yml.dig(mailbox_type.to_s, 'signing_key_file') ||
          raise(MissingSecretError, <<~MSG)
            No JWT signing key configured. Add a `signing_key_file:` entry under
            `#{mailbox_type}:` in config/gitlab.yml pointing to the PEM-encoded
            private key, and configure the matching public key on the cells.
          MSG
      end

      # Builds mail_room mailbox attribute hashes for every enabled GitLab
      # mailbox, read from config/gitlab.yml. This is the single source of truth
      # for the IMAP settings, mirroring the GitLab application's own mail_room
      # so the service polls the same mailboxes without duplicating credentials.
      #
      # @return [Array<Hash>] attributes accepted by MailRoom::Mailbox
      def mailboxes
        MAILBOX_TYPES.filter_map do |mailbox_type|
          settings = gitlab_yml[mailbox_type]
          next unless enabled?(settings)

          mailbox_attributes(mailbox_type, settings)
        end
      end

      # Arbitration lets several service instances poll the same mailbox without
      # double-processing: mail_room takes a short-lived Redis lock per message
      # (the same mechanism, and the same lock namespace, the existing GitLab
      # mailroom uses). Configured via `cell.email_forwarding.arbitration` in
      # config/gitlab.yml. When no Redis is configured (for example a local,
      # single-instance run) we fall back to mail_room's default "noop"
      # arbitration.
      #
      # @return [Hash] `{ arbitration_method:, arbitration_options: }` merged into
      #   each mailbox's attributes
      def arbitration_attributes
        redis = arbitration_config
        redis_url = redis['redis_url']
        sentinels = redis['sentinels']

        return { arbitration_method: 'noop', arbitration_options: {} } unless redis_url || sentinels

        options = {
          redis_url: redis_url,
          namespace: ARBITRATION_NAMESPACE
        }
        options[:redis_ssl_params] = redis['redis_ssl_params'] if redis['redis_ssl_params']
        options[:sentinels] = sentinels if sentinels
        options[:sentinel_username] = redis['sentinel_username'] if redis['sentinel_username']
        options[:sentinel_password] = redis['sentinel_password'] if redis['sentinel_password']

        { arbitration_method: 'redis', arbitration_options: options }
      end

      private

      def arbitration_config
        cell_config.dig('email_forwarding', 'arbitration') || {}
      end

      def cell_endpoint_config
        cell_config.dig('email_forwarding', 'cell_endpoint') || {}
      end

      def enabled?(settings)
        settings.is_a?(Hash) && settings['enabled'] && !settings['address'].to_s.empty?
      end

      # `delete_after_delivery` and `expunge_deleted` are passed through
      # explicitly: mail_room defaults both to false, so omitting them would
      # leave delivered mail in the mailbox forever, unlike the existing GitLab
      # mailroom which flags delivered messages as deleted.
      def mailbox_attributes(mailbox_type, settings)
        {
          email: settings['user'],
          password: settings['password'],
          host: settings['host'],
          port: settings['port'],
          ssl: settings['ssl'],
          start_tls: settings['start_tls'],
          name: settings['mailbox'] || 'inbox',
          idle_timeout: settings['idle_timeout'],
          delete_after_delivery: settings['delete_after_delivery'],
          expunge_deleted: settings['expunge_deleted'],
          delivery_options: {
            mailbox_type: mailbox_type,
            wildcard_address: settings['address']
          }
        }
      end

      def cell_config
        gitlab_yml['cell'] || {}
      end

      def topology_service_config
        cell_config['topology_service_client'] || {}
      end

      def gitlab_yml
        @gitlab_yml ||= begin
          raw = ERB.new(File.read(config_file)).result
          YAML.safe_load(raw, aliases: true).fetch(@rails_env)
        end
      end

      def config_file
        ENV[CONFIG_FILE_ENV] || File.join(@rails_root, DEFAULT_CONFIG_FILE)
      end
    end
  end
end
