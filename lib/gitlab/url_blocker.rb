require 'resolv'

module Gitlab
  class UrlBlocker
    class << self
      def blocked_url?(url, allow_private_networks: true, valid_ports: [])
        return false if url.nil?

        blocked_ips = ["127.0.0.1", "::1", "0.0.0.0"]
        blocked_ips.concat(Socket.ip_address_list.map(&:ip_address))

        begin
          uri = Addressable::URI.parse(url)
          # Allow imports from the GitLab instance itself but only from the configured ports
          return false if internal?(uri)

          return true if blocked_port?(uri.port, valid_ports)
          return true if blocked_user_or_hostname?(uri.user)
          return true if blocked_user_or_hostname?(uri.hostname)

          addrs_info = Addrinfo.getaddrinfo(uri.hostname, 80, nil, :STREAM)
          server_ips = addrs_info.map(&:ip_address)

          return true if (blocked_ips & server_ips).any?
          return true if !allow_private_networks && private_network?(addrs_info)
        rescue Addressable::URI::InvalidURIError
          return true
        rescue SocketError
          return false
        end

        false
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

      def private_network?(addrs_info)
        addrs_info.any? { |addr| addr.ipv4_private? || addr.ipv6_sitelocal? }
      end

      def config
        Gitlab.config
      end
    end
  end
end
