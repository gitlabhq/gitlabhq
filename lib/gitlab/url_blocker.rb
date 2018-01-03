require 'resolv'

module Gitlab
  class UrlBlocker
    class << self
      # Used to specify what hosts and port numbers should be prohibited for project
      # imports.
      VALID_PORTS = [22, 80, 443].freeze

      def blocked_url?(url)
        return false if url.nil?

        blocked_ips = ["127.0.0.1", "::1", "0.0.0.0"]
        blocked_ips.concat(Socket.ip_address_list.map(&:ip_address))

        begin
          uri = Addressable::URI.parse(url)
          # Allow imports from the GitLab instance itself but only from the configured ports
          return false if internal?(uri)

          return true if blocked_port?(uri.port)
          return true if blocked_user_or_hostname?(uri.user)
          return true if blocked_user_or_hostname?(uri.hostname)

          server_ips = Addrinfo.getaddrinfo(uri.hostname, 80, nil, :STREAM).map(&:ip_address)
          return true if (blocked_ips & server_ips).any?
        rescue Addressable::URI::InvalidURIError
          return true
        rescue SocketError
          return false
        end

        false
      end

      private

      def blocked_port?(port)
        return false if port.blank?

        port < 1024 && !VALID_PORTS.include?(port)
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

      def config
        Gitlab.config
      end
    end
  end
end
