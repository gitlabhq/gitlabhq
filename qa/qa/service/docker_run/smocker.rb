# frozen_string_literal: true

module QA
  module Service
    module DockerRun
      class Smocker < Base
        def initialize
          @image = 'thiht/smocker:0.17.1'
          @name = 'smocker-server'
          @public_port = 8080
          @admin_port = 8081
          super
          @network_cache = network
        end

        # @param wait [Integer] seconds to wait for server
        # @yieldparam [SmockerApi] the api object ready for interaction
        def self.init(wait: 10)
          if @container.nil?
            @container = new
            @container.register!
            @container.wait_for_running

            @api = Vendor::Smocker::SmockerApi.new(
              host: @container.host_name,
              public_port: @container.public_port,
              admin_port: @container.admin_port
            )
            @api.wait_for_ready(wait: wait)
          end

          yield @api
        end

        def self.teardown!
          @container&.remove!
          @container = nil
          @api = nil
        end

        attr_reader :public_port, :admin_port

        def host_name
          return '127.0.0.1' unless QA::Runtime::Env.running_in_ci? || QA::Runtime::Env.qa_hostname

          "#{@name}.#{@network_cache}"
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
