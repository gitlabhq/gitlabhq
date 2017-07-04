module SystemCheck
  module Geo
    class HttpConnectionCheck < SystemCheck::BaseCheck
      set_name 'GitLab Geo HTTP(S) connectivity'
      set_skip_reason 'Geo is not enabled'

      def skip?
        !Gitlab::Geo.enabled?
      end

      def multi_check
        $stdout.puts
        if Gitlab::Geo.primary?
          Gitlab::Geo.secondary_nodes.each do |node|
            $stdout.print "* Can connect to secondary node: '#{node.url}' ... "
            check_gitlab_geo_node(node)
          end
        end

        if Gitlab::Geo.secondary?
          $stdout.print '* Can connect to the primary node ... '
          check_gitlab_geo_node(Gitlab::Geo.primary_node)
        end
      end

      private

      def check_gitlab_geo_node(node)
        response = Net::HTTP.start(node.uri.host, node.uri.port, use_ssl: (node.uri.scheme == 'https')) do |http|
          http.request(Net::HTTP::Get.new(node.uri))
        end

        if response.code_type == Net::HTTPFound
          $stdout.puts 'yes'.color(:green)
        else
          $stdout.puts 'no'.color(:red)
        end
      rescue Errno::ECONNREFUSED => e
        display_exception(e)

        try_fixing_it(
          'Check if the machine is online and GitLab is running',
          'Check your firewall rules and make sure this machine can reach the target machine',
          "Make sure port and protocol are correct: '#{node.url}', or change it in Admin > Geo Nodes"
        )
      rescue SocketError => e
        display_exception(e)

        if e.cause && e.cause.message.starts_with?('getaddrinfo')
          try_fixing_it(
            'Check if your machine can connect to a DNS server',
            "Check if your machine can resolve DNS for: '#{node.uri.host}'",
            'If machine host is incorrect, change it in Admin > Geo Nodes'
          )
        end
      rescue OpenSSL::SSL::SSLError => e
        display_exception(e)

        try_fixing_it(
          'If you have a self-signed CA or certificate you need to whitelist it in Omnibus'
        )
        for_more_information(see_custom_certificate_doc)

        try_fixing_it(
          'If you have a valid certificate make sure you have the full certificate chain in the pem file'
        )
      rescue StandardError => e
        display_exception(e)
      end

      def display_exception(exception)
        $stdout.puts 'no'.color(:red)
        $stdout.puts '  Reason:'.color(:blue)
        $stdout.puts "  #{exception.message}"
      end
    end
  end
end
