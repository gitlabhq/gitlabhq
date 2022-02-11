# frozen_string_literal: true

module QA
  module Service
    module DockerRun
      class Smocker < Base
        def initialize
          @image = 'thiht/smocker:0.17.1'
          @name = 'smocker-server'
          @public_port = '8080'
          @admin_port = '8081'
          super
          @network_cache = network
        end

        def host_name
          return '127.0.0.1' unless QA::Runtime::Env.running_in_ci? || QA::Runtime::Env.qa_hostname

          "#{@name}.#{@network_cache}"
        end

        def base_url
          "http://#{host_name}:#{@public_port}"
        end

        def admin_url
          "http://#{host_name}:#{@admin_port}"
        end

        def wait_for_running
          Support::Waiter.wait_until(raise_on_failure: false, reload_page: false) do
            running?
          end
        end

        def register!
          command = <<~CMD.tr("\n", ' ')
            docker run -d --rm
            --network #{@network_cache}
            --hostname #{host_name}
            --name #{@name}
            --publish #{@public_port}:8080
            --publish #{@admin_port}:8081
            #{@image}
          CMD

          unless QA::Runtime::Env.running_in_ci? || QA::Runtime::Env.qa_hostname
            command.gsub!("--network #{@network_cache} ", '')
          end

          shell command
        end
      end
    end
  end
end
