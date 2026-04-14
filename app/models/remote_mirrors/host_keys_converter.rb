# frozen_string_literal: true

module RemoteMirrors
  # Converts host_keys array (API format) to ssh_known_hosts string (internal format)
  #
  # Accepts two formats for host keys:
  # 1. Bare key format: "ssh-ed25519 AAAA..." - hostname is extracted from the URL
  # 2. Full known_hosts format: "hostname ssh-ed25519 AAAA..." - hostname is preserved
  #
  # @example Bare key format (hostname extracted from URL)
  #   converter = HostKeysConverter.new(['ssh-ed25519 AAAA...'], url: 'ssh://git@example.com/repo.git')
  #   converter.to_ssh_known_hosts!
  #   # => "example.com ssh-ed25519 AAAA..."
  #
  # @example Full known_hosts format (hostname preserved)
  #   keys = ['git.example.org ssh-ed25519 AAAA...']
  #   converter = HostKeysConverter.new(keys, url: 'ssh://git@example.com/repo.git')
  #   converter.to_ssh_known_hosts!
  #   # => "git.example.org ssh-ed25519 AAAA..."
  #
  # @example Non-standard port
  #   converter = HostKeysConverter.new(['ssh-ed25519 AAAA...'], url: 'ssh://git@example.com:2222/repo.git')
  #   converter.to_ssh_known_hosts!
  #   # => "[example.com]:2222 ssh-ed25519 AAAA..."
  #
  class HostKeysConverter
    include Gitlab::Utils::StrongMemoize

    class InvalidHostKeyError < StandardError
      attr_reader :invalid_keys

      def initialize(invalid_keys)
        @invalid_keys = invalid_keys
        super("Invalid SSH host key(s): #{invalid_keys.join(', ')}")
      end
    end

    STANDARD_SSH_PORT = 22
    MAX_HOST_KEYS = 10

    # Matches lines starting with hostname followed by key type
    # Examples that match: "example.com ssh-ed25519", "host,ip ecdsa-sha2-nistp256", "[host]:2222 ssh-rsa"
    # Examples that don't match: "ssh-ed25519 AAAA...", "ecdsa-sha2-nistp256 AAAA..."
    KEY_WITH_HOSTNAME_REGEX = /\A\S+\s+(ssh-|ecdsa-)/

    def initialize(host_keys, url:)
      @host_keys = host_keys || []
      @url = url
    end

    def to_ssh_known_hosts!
      return if host_keys.blank?

      validate!

      normalized_keys = sanitized_keys.filter_map do |key|
        normalize_key(key)
      end

      normalized_keys.join("\n").presence
    end

    private

    attr_reader :host_keys, :url

    def validate!
      raise InvalidHostKeyError, ["too many host keys (maximum is #{MAX_HOST_KEYS})"] if host_keys.size > MAX_HOST_KEYS

      invalid = sanitized_keys.filter_map do |key|
        next if key.blank?

        key unless Gitlab::SSHPublicKey.new(key).valid?
      end

      raise InvalidHostKeyError, invalid if invalid.present?
    end

    def sanitized_keys
      @sanitized_keys ||= host_keys.map do |key|
        sanitize_key(key.to_s.strip)
      end
    end

    def sanitize_key(key)
      parts = Gitlab::SSHPublicKey.extract_key_parts(key)
      return key unless parts

      [parts[:prefix].presence, parts[:algorithm], restore_base64_encoding(parts[:key_data])].compact.join(' ')
    end

    # Form-encoded params (application/x-www-form-urlencoded) decode '+' as spaces.
    # SSH key base64 data uses '+' characters, so we restore them here.
    def restore_base64_encoding(key_data)
      key_data.tr(' ', '+')
    end

    def normalize_key(key)
      return if key.blank?
      return key if key.match?(KEY_WITH_HOSTNAME_REGEX)

      raise InvalidHostKeyError, ["cannot determine hostname from URL for bare key"] if known_hosts_hostname.blank?

      "#{known_hosts_hostname} #{key}"
    end

    def known_hosts_hostname
      return if url.blank?

      uri = Addressable::URI.parse(url)
      host = uri.host
      return if host.blank?

      port = uri.port
      return host if port.nil? || port == STANDARD_SSH_PORT

      "[#{host}]:#{port}"
    rescue Addressable::URI::InvalidURIError
      nil
    end
    strong_memoize_attr :known_hosts_hostname
  end
end
