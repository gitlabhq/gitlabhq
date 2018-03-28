require 'resolv'

module Gitlab
  class UrlBlocker
    BlockedUrlError = Class.new(StandardError)

    class << self
      def validate!(url, allow_localhost: false, allow_private_networks: true, valid_ports: [])
        return true if url.nil?

        begin
          uri = Addressable::URI.parse(url)
          # Allow imports from the GitLab instance itself but only from the configured ports
          return true if internal?(uri)

          raise BlockedUrlError, "Port is blocked" if blocked_port?(uri.port, valid_ports)
          raise BlockedUrlError, "User is blocked" if blocked_user_or_hostname?(uri.user)
          raise BlockedUrlError, "Hostname is blocked" if blocked_user_or_hostname?(uri.hostname)

          addrs_info = Addrinfo.getaddrinfo(uri.hostname, 80, nil, :STREAM)

          if !allow_localhost && localhost?(addrs_info)
            raise BlockedUrlError, "Requests to localhost are blocked"
          end

          if !allow_private_networks && private_network?(addrs_info)
            raise BlockedUrlError, "Requests to the private local network are blocked"
          end
        rescue Addressable::URI::InvalidURIError
          raise BlockedUrlError, "URI is invalid"
        rescue SocketError
          return
        end

        true
      end

      def blocked_url?(*args)
        validate!(*args)

        false
      rescue BlockedUrlError
        true
      end

      private

      def blocked_port?(port, valid_ports)
        return false if port.blank? || valid_ports.blank?

        port < 1024 && !valid_ports.include?(port)
      end

      def blocked_user_or_hostname?(value)
        return false if value.blank?

        value !~ /\A\p{Alnum}/
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

      def localhost?(addrs_info)
        blocked_ips = ["127.0.0.1", "::1", "0.0.0.0"]
        blocked_ips.concat(Socket.ip_address_list.map(&:ip_address))

        (blocked_ips & addrs_info.map(&:ip_address)).any?
      end

      def private_network?(addrs_info)
        addrs_info.any? { |addr| addr.ipv4_private? || addr.ipv6_sitelocal? }
      end

      def config
        Gitlab.config
      end
    end
  end
end
