# frozen_string_literal: true

module QA
  module Service
    module DockerRun
      class LDAP < Base
        def initialize(volume)
          @image = 'osixia/openldap:latest'
          @name = 'ldap-server'
          @volume = volume

          super()
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

        def volume_or_fixture(volume_name)
          if volume_exists?(volume_name)
            volume_name
          else
            Runtime::Path.fixture('ldap', volume_name)
          end
        end

        def volume_exists?(volume_name)
          `docker volume ls -q -f name=#{volume_name}`.include?(volume_name)
        end
      end
    end
  end
end
