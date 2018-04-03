require 'resolv'

module Gitlab
  class UrlBlocker
    BlockedUrlError = Class.new(StandardError)

    class << self
      def validate!(url, allow_localhost: false, allow_local_network: true, valid_ports: [])
        return true if url.nil?

        begin
          uri = Addressable::URI.parse(url)
        rescue Addressable::URI::InvalidURIError
          raise BlockedUrlError, "URI is invalid"
        end

        # Allow imports from the GitLab instance itself but only from the configured ports
        return true if internal?(uri)

        port = uri.port || uri.default_port
        validate_port!(port, valid_ports) if valid_ports.any?
        validate_user!(uri.user)
        validate_hostname!(uri.hostname)

        begin
          addrs_info = Addrinfo.getaddrinfo(uri.hostname, port, nil, :STREAM)
        rescue SocketError
          return true
        end

        validate_localhost!(addrs_info) unless allow_localhost
        validate_local_network!(addrs_info) unless allow_local_network

        true
      end

      def blocked_url?(*args)
        validate!(*args)

        false
      rescue BlockedUrlError
        true
      end

      private

      def validate_port!(port, valid_ports)
        return if port.blank?
        # Only ports under 1024 are restricted
        return if port >= 1024
        return if valid_ports.include?(port)

        raise BlockedUrlError, "Only allowed ports are #{valid_ports.join(', ')}, and any over 1024"
      end

      def validate_user!(value)
        return if value.blank?
        return if value =~ /\A\p{Alnum}/

        raise BlockedUrlError, "Username needs to start with an alphanumeric character"
      end

      def validate_hostname!(value)
        return if value.blank?
        return if value =~ /\A\p{Alnum}/

        raise BlockedUrlError, "Hostname needs to start with an alphanumeric character"
      end

      def validate_localhost!(addrs_info)
        local_ips = ["127.0.0.1", "::1", "0.0.0.0"]
        local_ips.concat(Socket.ip_address_list.map(&:ip_address))

        return if (local_ips & addrs_info.map(&:ip_address)).empty?

        raise BlockedUrlError, "Requests to localhost are not allowed"
      end

      def validate_local_network!(addrs_info)
        return unless addrs_info.any? { |addr| addr.ipv4_private? || addr.ipv6_sitelocal? }

        raise BlockedUrlError, "Requests to the local network are not allowed"
      end

      def internal?(uri)
        internal_web?(uri) || internal_shell?(uri)
      end

      def internal_web?(uri)
        uri.hostname == config.gitlab.host &&
          (uri.port.blank? || uri.port == config.gitlab.port)
      end

      def internal_shell?(uri)
        uri.hostname == config.gitlab_shell.ssh_host &&
          (uri.port.blank? || uri.port == config.gitlab_shell.ssh_port)
      end

      def config
        Gitlab.config
      end
    end
  end
end
