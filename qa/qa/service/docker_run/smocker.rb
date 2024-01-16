# frozen_string_literal: true

module QA
  module Service
    module DockerRun
      class Smocker < Base
        def initialize(name: 'smocker-server')
          @image = 'thiht/smocker:0.18.5'
          @name = name
          @public_port = 8080
          @admin_port = 8081

          super()
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

        def wait_for_running
          Support::Waiter.wait_until(raise_on_failure: false, reload_page: false) do
            running?
          end
        end

        def register!
          command = <<~CMD.tr("\n", ' ')
            docker run -d --rm
            --network #{network}
            --name #{name}
            --publish #{public_port}:8080
            --publish #{admin_port}:8081
            #{image}
          CMD

          shell command
        end

        private

        attr_reader :name, :image
      end
    end
  end
end
