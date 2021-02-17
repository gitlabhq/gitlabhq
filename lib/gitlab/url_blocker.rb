# frozen_string_literal: true

require 'resolv'
require 'ipaddress'

module Gitlab
  class UrlBlocker
    BlockedUrlError = Class.new(StandardError)

    class << self
      # Validates the given url according to the constraints specified by arguments.
      #
      # ports - Raises error if the given URL port does is not between given ports.
      # allow_localhost - Raises error if URL resolves to a localhost IP address and argument is false.
      # allow_local_network - Raises error if URL resolves to a link-local address and argument is false.
      # ascii_only - Raises error if URL has unicode characters and argument is true.
      # enforce_user - Raises error if URL user doesn't start with alphanumeric characters and argument is true.
      # enforce_sanitization - Raises error if URL includes any HTML/CSS/JS tags and argument is true.
      #
      # Returns an array with [<uri>, <original-hostname>].
      # rubocop:disable Metrics/ParameterLists
      def validate!(
        url,
        ports: [],
        schemes: [],
        allow_localhost: false,
        allow_local_network: true,
        ascii_only: false,
        enforce_user: false,
        enforce_sanitization: false,
        dns_rebind_protection: true)
        # rubocop:enable Metrics/ParameterLists

        return [nil, nil] if url.nil?

        # Param url can be a string, URI or Addressable::URI
        uri = parse_url(url)

        validate_uri(
          uri: uri,
          schemes: schemes,
          ports: ports,
          enforce_sanitization: enforce_sanitization,
          enforce_user: enforce_user,
          ascii_only: ascii_only
        )

        address_info = get_address_info(uri, dns_rebind_protection)
        return [uri, nil] unless address_info

        ip_address = ip_address(address_info)
        return [uri, nil] if domain_allowed?(uri)

        protected_uri_with_hostname = enforce_uri_hostname(ip_address, uri, dns_rebind_protection)

        return protected_uri_with_hostname if ip_allowed?(ip_address, port: get_port(uri))

        # Allow url from the GitLab instance itself but only for the configured hostname and ports
        return protected_uri_with_hostname if internal?(uri)

        validate_local_request(
          address_info: address_info,
          allow_localhost: allow_localhost,
          allow_local_network: allow_local_network
        )

        protected_uri_with_hostname
      end

      def blocked_url?(url, **kwargs)
        validate!(url, **kwargs)

        false
      rescue BlockedUrlError
        true
      end

      private

      # Returns the given URI with IP address as hostname and the original hostname respectively
      # in an Array.
      #
      # It checks whether the resolved IP address matches with the hostname. If not, it changes
      # the hostname to the resolved IP address.
      #
      # The original hostname is used to validate the SSL, given in that scenario
      # we'll be making the request to the IP address, instead of using the hostname.
      def enforce_uri_hostname(ip_address, uri, dns_rebind_protection)
        return [uri, nil] unless dns_rebind_protection && ip_address && ip_address != uri.hostname

        new_uri = uri.dup
        new_uri.hostname = ip_address
        [new_uri, uri.hostname]
      end

      def ip_address(address_info)
        address_info.first&.ip_address
      end

      def validate_uri(uri:, schemes:, ports:, enforce_sanitization:, enforce_user:, ascii_only:)
        validate_html_tags(uri) if enforce_sanitization

        return if internal?(uri)

        validate_scheme(uri.scheme, schemes)
        validate_port(get_port(uri), ports) if ports.any?
        validate_user(uri.user) if enforce_user
        validate_hostname(uri.hostname)
        validate_unicode_restriction(uri) if ascii_only
      end

      def get_address_info(uri, dns_rebind_protection)
        Addrinfo.getaddrinfo(uri.hostname, get_port(uri), nil, :STREAM).map do |addr|
          addr.ipv6_v4mapped? ? addr.ipv6_to_ipv4 : addr
        end
      rescue SocketError
        # If the dns rebinding protection is not enabled or the domain
        # is allowed we avoid the dns rebinding checks
        return if domain_allowed?(uri) || !dns_rebind_protection

        # In the test suite we use a lot of mocked urls that are either invalid or
        # don't exist. In order to avoid modifying a ton of tests and factories
        # we allow invalid urls unless the environment variable RSPEC_ALLOW_INVALID_URLS
        # is not true
        return if Rails.env.test? && ENV['RSPEC_ALLOW_INVALID_URLS'] == 'true'

        # If the addr can't be resolved or the url is invalid (i.e http://1.1.1.1.1)
        # we block the url
        raise BlockedUrlError, "Host cannot be resolved or invalid"
      rescue ArgumentError => error
        # Addrinfo.getaddrinfo errors if the domain exceeds 1024 characters.
        raise unless error.message.include?('hostname too long')

        raise BlockedUrlError, "Host is too long (maximum is 1024 characters)"
      end

      def validate_local_request(
        address_info:,
        allow_localhost:,
        allow_local_network:)
        return if allow_local_network && allow_localhost

        unless allow_localhost
          validate_localhost(address_info)
          validate_loopback(address_info)
        end

        unless allow_local_network
          validate_local_network(address_info)
          validate_link_local(address_info)
        end
      end

      def get_port(uri)
        uri.port || uri.default_port
      end

      def validate_html_tags(uri)
        uri_str = uri.to_s
        sanitized_uri = ActionController::Base.helpers.sanitize(uri_str, tags: [])
        if sanitized_uri != uri_str
          raise BlockedUrlError, 'HTML/CSS/JS tags are not allowed'
        end
      end

      def parse_url(url)
        raise Addressable::URI::InvalidURIError if multiline?(url)

        Addressable::URI.parse(url)
      rescue Addressable::URI::InvalidURIError, URI::InvalidURIError
        raise BlockedUrlError, 'URI is invalid'
      end

      def multiline?(url)
        CGI.unescape(url.to_s) =~ /\n|\r/
      end

      def validate_port(port, ports)
        return if port.blank?
        # Only ports under 1024 are restricted
        return if port >= 1024
        return if ports.include?(port)

        raise BlockedUrlError, "Only allowed ports are #{ports.join(', ')}, and any over 1024"
      end

      def validate_scheme(scheme, schemes)
        if scheme.blank? || (schemes.any? && !schemes.include?(scheme))
          raise BlockedUrlError, "Only allowed schemes are #{schemes.join(', ')}"
        end
      end

      def validate_user(value)
        return if value.blank?
        return if value =~ /\A\p{Alnum}/

        raise BlockedUrlError, "Username needs to start with an alphanumeric character"
      end

      def validate_hostname(value)
        return if value.blank?
        return if IPAddress.valid?(value)
        return if value =~ /\A\p{Alnum}/

        raise BlockedUrlError, "Hostname or IP address invalid"
      end

      def validate_unicode_restriction(uri)
        return if uri.to_s.ascii_only?

        raise BlockedUrlError, "URI must be ascii only #{uri.to_s.dump}"
      end

      def validate_localhost(addrs_info)
        local_ips = ["::", "0.0.0.0"]
        local_ips.concat(Socket.ip_address_list.map(&:ip_address))

        return if (local_ips & addrs_info.map(&:ip_address)).empty?

        raise BlockedUrlError, "Requests to localhost are not allowed"
      end

      def validate_loopback(addrs_info)
        return unless addrs_info.any? { |addr| addr.ipv4_loopback? || addr.ipv6_loopback? }

        raise BlockedUrlError, "Requests to loopback addresses are not allowed"
      end

      def validate_local_network(addrs_info)
        return unless addrs_info.any? { |addr| addr.ipv4_private? || addr.ipv6_sitelocal? || addr.ipv6_unique_local? }

        raise BlockedUrlError, "Requests to the local network are not allowed"
      end

      def validate_link_local(addrs_info)
        netmask = IPAddr.new('169.254.0.0/16')
        return unless addrs_info.any? { |addr| addr.ipv6_linklocal? || netmask.include?(addr.ip_address) }

        raise BlockedUrlError, "Requests to the link local network are not allowed"
      end

      def internal?(uri)
        internal_web?(uri) || internal_shell?(uri)
      end

      def internal_web?(uri)
        uri.scheme == config.gitlab.protocol &&
          uri.hostname == config.gitlab.host &&
          (uri.port.blank? || uri.port == config.gitlab.port)
      end

      def internal_shell?(uri)
        uri.scheme == 'ssh' &&
          uri.hostname == config.gitlab_shell.ssh_host &&
          (uri.port.blank? || uri.port == config.gitlab_shell.ssh_port)
      end

      def domain_allowed?(uri)
        Gitlab::UrlBlockers::UrlAllowlist.domain_allowed?(uri.normalized_host, port: get_port(uri))
      end

      def ip_allowed?(ip_address, port: nil)
        Gitlab::UrlBlockers::UrlAllowlist.ip_allowed?(ip_address, port: port)
      end

      def config
        Gitlab.config
      end
    end
  end
end
