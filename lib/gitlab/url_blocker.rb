# frozen_string_literal: true

require 'resolv'
require 'ipaddress'

module Gitlab
  class UrlBlocker
    BlockedUrlError = Class.new(StandardError)

    class << self
      def validate!(url, ports: [], schemes: [], allow_localhost: false, allow_local_network: true, ascii_only: false, enforce_user: false, enforce_sanitization: false)
        return true if url.nil?

        # Param url can be a string, URI or Addressable::URI
        uri = parse_url(url)

        validate_html_tags!(uri) if enforce_sanitization

        # Allow imports from the GitLab instance itself but only from the configured ports
        return true if internal?(uri)

        port = get_port(uri)
        validate_scheme!(uri.scheme, schemes)
        validate_port!(port, ports) if ports.any?
        validate_user!(uri.user) if enforce_user
        validate_hostname!(uri.hostname)
        validate_unicode_restriction!(uri) if ascii_only

        begin
          addrs_info = Addrinfo.getaddrinfo(uri.hostname, port, nil, :STREAM).map do |addr|
            addr.ipv6_v4mapped? ? addr.ipv6_to_ipv4 : addr
          end
        rescue SocketError
          return true
        end

        validate_localhost!(addrs_info) unless allow_localhost
        validate_loopback!(addrs_info) unless allow_localhost
        validate_local_network!(addrs_info) unless allow_local_network
        validate_link_local!(addrs_info) unless allow_local_network

        true
      end

      def blocked_url?(*args)
        validate!(*args)

        false
      rescue BlockedUrlError
        true
      end

      private

      def get_port(uri)
        uri.port || uri.default_port
      end

      def validate_html_tags!(uri)
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

      def validate_port!(port, ports)
        return if port.blank?
        # Only ports under 1024 are restricted
        return if port >= 1024
        return if ports.include?(port)

        raise BlockedUrlError, "Only allowed ports are #{ports.join(', ')}, and any over 1024"
      end

      def validate_scheme!(scheme, schemes)
        if scheme.blank? || (schemes.any? && !schemes.include?(scheme))
          raise BlockedUrlError, "Only allowed schemes are #{schemes.join(', ')}"
        end
      end

      def validate_user!(value)
        return if value.blank?
        return if value =~ /\A\p{Alnum}/

        raise BlockedUrlError, "Username needs to start with an alphanumeric character"
      end

      def validate_hostname!(value)
        return if value.blank?
        return if IPAddress.valid?(value)
        return if value =~ /\A\p{Alnum}/

        raise BlockedUrlError, "Hostname or IP address invalid"
      end

      def validate_unicode_restriction!(uri)
        return if uri.to_s.ascii_only?

        raise BlockedUrlError, "URI must be ascii only #{uri.to_s.dump}"
      end

      def validate_localhost!(addrs_info)
        local_ips = ["::", "0.0.0.0"]
        local_ips.concat(Socket.ip_address_list.map(&:ip_address))

        return if (local_ips & addrs_info.map(&:ip_address)).empty?

        raise BlockedUrlError, "Requests to localhost are not allowed"
      end

      def validate_loopback!(addrs_info)
        return unless addrs_info.any? { |addr| addr.ipv4_loopback? || addr.ipv6_loopback? }

        raise BlockedUrlError, "Requests to loopback addresses are not allowed"
      end

      def validate_local_network!(addrs_info)
        return unless addrs_info.any? { |addr| addr.ipv4_private? || addr.ipv6_sitelocal? || addr.ipv6_unique_local? }

        raise BlockedUrlError, "Requests to the local network are not allowed"
      end

      def validate_link_local!(addrs_info)
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

      def config
        Gitlab.config
      end
    end
  end
end
