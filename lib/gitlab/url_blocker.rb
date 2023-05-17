# frozen_string_literal: true

require 'resolv'
require 'ipaddress'

module Gitlab
  class UrlBlocker
    BlockedUrlError = Class.new(StandardError)

    DENY_ALL_REQUESTS_EXCEPT_ALLOWED_DEFAULT = proc { deny_all_requests_except_allowed_app_setting }.freeze

    # Result stores the validation result:
    # uri - The original URI requested
    # hostname - The hostname that should be used to connect. For DNS
    #   rebinding protection, this will be the resolved IP address of
    #   the hostname.
    # use_proxy -
    #   If true, this means that the proxy server specified in the
    #   http_proxy/https_proxy environment variables should be used.
    #
    #   If false, this either means that no proxy server was specified
    #   or that the hostname in the URL is exempt via the no_proxy
    #   environment variable. This allows the caller to disable usage
    #   of a proxy since the IP address may be used to
    #   connect. Otherwise, Net::HTTP may erroneously compare the IP
    #   address against the no_proxy list.
    Result = Struct.new(:uri, :hostname, :use_proxy)

    class << self
      # Validates the given url according to the constraints specified by arguments.
      #
      # ports - Raises error if the given URL port is not between given ports.
      # allow_localhost - Raises error if URL resolves to a localhost IP address and argument is false.
      # allow_local_network - Raises error if URL resolves to a link-local address and argument is false.
      # allow_object_storage - Avoid raising an error if URL resolves to an object storage endpoint and argument is true.
      # ascii_only - Raises error if URL has unicode characters and argument is true.
      # enforce_user - Raises error if URL user doesn't start with alphanumeric characters and argument is true.
      # enforce_sanitization - Raises error if URL includes any HTML/CSS/JS tags and argument is true.
      # deny_all_requests_except_allowed - Raises error if URL is not in the allow list and argument is true. Can be Boolean or Proc. Defaults to instance app setting.
      #
      # Returns a Result object.
      # rubocop:disable Metrics/ParameterLists
      def validate_url_with_proxy!(
        url,
        schemes:,
        ports: [],
        allow_localhost: false,
        allow_local_network: true,
        allow_object_storage: false,
        ascii_only: false,
        enforce_user: false,
        enforce_sanitization: false,
        deny_all_requests_except_allowed: DENY_ALL_REQUESTS_EXCEPT_ALLOWED_DEFAULT,
        dns_rebind_protection: true)
        # rubocop:enable Metrics/ParameterLists

        return Result.new(nil, nil, true) if url.nil?

        raise ArgumentError, 'The schemes is a required argument' if schemes.blank?

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

        begin
          address_info = get_address_info(uri)
        rescue SocketError
          proxy_in_use = uri_under_proxy_setting?(uri, nil)

          return Result.new(uri, nil, proxy_in_use) unless enforce_address_info_retrievable?(uri, dns_rebind_protection, deny_all_requests_except_allowed)

          raise BlockedUrlError, 'Host cannot be resolved or invalid'
        end

        ip_address = ip_address(address_info)
        proxy_in_use = uri_under_proxy_setting?(uri, ip_address)

        # Ignore DNS rebind protection when a proxy is being used, as DNS
        # rebinding is expected behavior.
        dns_rebind_protection &&= !proxy_in_use
        return Result.new(uri, nil, proxy_in_use) if domain_in_allow_list?(uri)

        protected_uri_with_hostname = enforce_uri_hostname(ip_address, uri, dns_rebind_protection, proxy_in_use)

        return protected_uri_with_hostname if ip_in_allow_list?(ip_address, port: get_port(uri))

        # Allow url from the GitLab instance itself but only for the configured hostname and ports
        return protected_uri_with_hostname if internal?(uri)

        return protected_uri_with_hostname if allow_object_storage && object_storage_endpoint?(uri)

        validate_deny_all_requests_except_allowed!(deny_all_requests_except_allowed)

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

      # For backwards compatibility, Returns an array with [<uri>, <original-hostname>].
      # Issue for refactoring: https://gitlab.com/gitlab-org/gitlab/-/issues/410890
      def validate!(...)
        result = validate_url_with_proxy!(...)
        [result.uri, result.hostname]
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
      def enforce_uri_hostname(ip_address, uri, dns_rebind_protection, proxy_in_use)
        return Result.new(uri, nil, proxy_in_use) unless dns_rebind_protection && ip_address && ip_address != uri.hostname

        new_uri = uri.dup
        new_uri.hostname = ip_address
        Result.new(new_uri, uri.hostname, proxy_in_use)
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

      def uri_under_proxy_setting?(uri, ip_address)
        return false unless Gitlab.http_proxy_env?
        # `no_proxy|NO_PROXY` specifies addresses for which the proxy is not
        # used. If it's empty, there are no exceptions and this URI
        # will be under proxy settings.
        return true if no_proxy_env.blank?

        # `no_proxy|NO_PROXY` is being used. We must check whether it
        # applies to this specific URI.
        ::URI::Generic.use_proxy?(uri.hostname, ip_address, get_port(uri), no_proxy_env)
      end

      # Returns addrinfo object for the URI.
      #
      # @param uri [Addressable::URI]
      #
      # @raise [Gitlab::UrlBlocker::BlockedUrlError, ArgumentError] - BlockedUrlError raised if host is too long.
      #
      # @return [Array<Addrinfo>]
      def get_address_info(uri)
        Addrinfo.getaddrinfo(uri.hostname, get_port(uri), nil, :STREAM).map do |addr|
          addr.ipv6_v4mapped? ? addr.ipv6_to_ipv4 : addr
        end
      rescue ArgumentError => error
        # Addrinfo.getaddrinfo errors if the domain exceeds 1024 characters.
        raise unless error.message.include?('hostname too long')

        raise BlockedUrlError, "Host is too long (maximum is 1024 characters)"
      end

      def enforce_address_info_retrievable?(uri, dns_rebind_protection, deny_all_requests_except_allowed)
        # Do not enforce if URI is in the allow list
        return false if domain_in_allow_list?(uri)

        # Enforce if the instance should block requests
        return true if deny_all_requests_except_allowed?(deny_all_requests_except_allowed)

        # Do not enforce if DNS rebinding protection is disabled
        return false unless dns_rebind_protection

        # Do not enforce if proxy is used
        return false if Gitlab.http_proxy_env?

        # In the test suite we use a lot of mocked urls that are either invalid or
        # don't exist. In order to avoid modifying a ton of tests and factories
        # we allow invalid urls unless the environment variable RSPEC_ALLOW_INVALID_URLS
        # is not true
        return false if Rails.env.test? && ENV['RSPEC_ALLOW_INVALID_URLS'] == 'true'

        true
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
          validate_shared_address(address_info)
          validate_limited_broadcast_address(address_info)
        end
      end

      def validate_shared_address(addrs_info)
        netmask = IPAddr.new('100.64.0.0/10')
        return unless addrs_info.any? { |addr| netmask.include?(addr.ip_address) }

        raise BlockedUrlError, "Requests to the shared address space are not allowed"
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
        Addressable::URI.parse(url).tap do |parsed_url|
          raise Addressable::URI::InvalidURIError if multiline_blocked?(parsed_url)
        end
      rescue Addressable::URI::InvalidURIError, URI::InvalidURIError
        raise BlockedUrlError, 'URI is invalid'
      end

      def multiline_blocked?(parsed_url)
        url = parsed_url.to_s

        return true if url =~ /\n|\r/
        # Google Cloud Storage uses a multi-line, encoded Signature query string
        return false if %w(http https).include?(parsed_url.scheme&.downcase)

        CGI.unescape(url) =~ /\n|\r/
      end

      def validate_port(port, ports)
        return if port.blank?
        # Only ports under 1024 are restricted
        return if port >= 1024
        return if ports.include?(port)

        raise BlockedUrlError, "Only allowed ports are #{ports.join(', ')}, and any over 1024"
      end

      def validate_scheme(scheme, schemes)
        if scheme.blank? || (schemes.any? && schemes.exclude?(scheme))
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

      # Raises a BlockedUrlError if the instance is configured to deny all requests.
      #
      # This should only be called after allow list checks have been made.
      def validate_deny_all_requests_except_allowed!(should_deny)
        return unless deny_all_requests_except_allowed?(should_deny)

        raise BlockedUrlError, "Requests to hosts and IP addresses not on the Allow List are denied"
      end

      # Raises a BlockedUrlError if any IP in `addrs_info` is the limited
      # broadcast address.
      # https://datatracker.ietf.org/doc/html/rfc919#section-7
      def validate_limited_broadcast_address(addrs_info)
        blocked_ips = ["255.255.255.255"]

        return if (blocked_ips & addrs_info.map(&:ip_address)).empty?

        raise BlockedUrlError, "Requests to the limited broadcast address are not allowed"
      end

      def internal?(uri)
        internal_web?(uri) || internal_shell?(uri)
      end

      def internal_web?(uri)
        uri.scheme == config.gitlab.protocol &&
          uri.hostname == config.gitlab.host &&
          get_port(uri) == config.gitlab.port
      end

      def internal_shell?(uri)
        uri.scheme == 'ssh' &&
          uri.hostname == config.gitlab_shell.ssh_host &&
          get_port(uri) == config.gitlab_shell.ssh_port
      end

      def enabled_object_storage_endpoints
        ObjectStoreSettings::SUPPORTED_TYPES.collect do |type|
          section_setting = config.try(type)

          next unless section_setting && section_setting['enabled']

          object_store_setting = section_setting['object_store']

          next unless object_store_setting && object_store_setting['enabled']

          object_store_setting.dig('connection', 'endpoint')
        end.compact.uniq
      end

      def deny_all_requests_except_allowed?(should_deny)
        should_deny.is_a?(Proc) ? should_deny.call : should_deny
      end

      def deny_all_requests_except_allowed_app_setting
        Gitlab::CurrentSettings.current_application_settings? &&
          Gitlab::CurrentSettings.deny_all_requests_except_allowed?
      end

      def object_storage_endpoint?(uri)
        enabled_object_storage_endpoints.any? do |endpoint|
          endpoint_uri = URI(endpoint)

          uri.scheme == endpoint_uri.scheme &&
            uri.hostname == endpoint_uri.hostname &&
            get_port(uri) == get_port(endpoint_uri)
        end
      end

      def domain_in_allow_list?(uri)
        Gitlab::UrlBlockers::UrlAllowlist.domain_allowed?(uri.normalized_host, port: get_port(uri))
      end

      def ip_in_allow_list?(ip_address, port: nil)
        Gitlab::UrlBlockers::UrlAllowlist.ip_allowed?(ip_address, port: port)
      end

      def config
        Gitlab.config
      end

      def no_proxy_env
        ENV['no_proxy'] || ENV['NO_PROXY']
      end
    end
  end
end
