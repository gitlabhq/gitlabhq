# frozen_string_literal: true

module QA
  module Service
    class LDAP
      include Service::Shellout

      def initialize(volume)
        @image = 'osixia/openldap:latest'
        @name = 'ldap-server'
        @network = Runtime::Scenario.attributes[:network] || 'test'
        @volume = volume
      end

      def network
        shell "docker network inspect #{@network}"
      rescue CommandError
        'bridge'
      else
        @network
      end

      def pull
        shell "docker pull #{@image}"
      end

      def host_name
        "#{@name}.#{network}"
      end

      def register!
        shell <<~CMD.tr("\n", ' ')
          docker run -d --rm
          --network #{network}
          --hostname #{host_name}
          --name #{@name}
          -p 389:389
          --volume #{volume_or_fixture(@volume)}:/container/service/slapd/assets/config/bootstrap/ldif/custom
          #{@image} --copy-service
        CMD
      end

      def remove!
        shell "docker rm -f #{@name}" if running?
      end

      def running?
        `docker ps -f name=#{@name}`.include?(@name)
      end

      def volume_or_fixture(volume_name)
        if volume_exists?(volume_name)
          volume_name
        else
          File.expand_path("../fixtures/ldap/#{volume_name}", __dir__)
        end
      end

      def volume_exists?(volume_name)
        `docker volume ls -q -f name=#{volume_name}`.include?(volume_name)
      end
    end
  end
end
