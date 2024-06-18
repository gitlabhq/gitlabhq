# frozen_string_literal: true

module QA
  module Service
    module DockerRun
      module ProductAnalytics
        class DotnetSdkApp < Base
          include Support::API

          def initialize(sdk_host, sdk_app_id)
            # Below is an image of a sample app that uses Product Analytics .NET SDK.
            # The image is created in https://gitlab.com/gitlab-org/analytics-section/product-analytics/gl-application-sdk-dotnet
            # It's built on every merge to main branch in the repository.
            # @name should not contain _ (underscores) as it is used to generate host_name
            # and _ are not allowed for domain names.
            @image = 'registry.gitlab.com/gitlab-org/analytics-section/product-analytics/' \
                     'gl-application-sdk-dotnet/example-app:main'
            @name = 'dotnet-sdk'
            @sdk_host = URI(sdk_host)
            @sdk_app_id = sdk_app_id
            @port = '5171'
            @host_name = 'localhost' unless Runtime::Env.running_in_ci?

            super()
          end

          def register!
            shell <<~CMD.tr("\n", ' ')
              docker run -d --rm
              --name #{@name}
              --network #{network}
              --hostname #{host_name}
              -p #{@port}:#{@port}
              -e PA_COLLECTOR_HOST=#{@sdk_host.host}
              -e PA_COLLECTOR_PORT=#{@sdk_host.port}
              -e PA_APPLICATION_ID=#{@sdk_app_id}
              #{@image}
            CMD

            wait_for_app_available
          end

          private

          def wait_for_app_available
            Runtime::Logger.info("Waiting for .NET SDK sample app to become available at http://#{host_name}:#{@port}...")
            Support::Waiter.wait_until(sleep_interval: 1,
              message: "Wait for .NET SDK sample app to become available at http://#{host_name}:#{@port}") { app_available? }
            Runtime::Logger.info('.NET SDK sample app is up and event is triggered!')
          end

          def app_available?
            response = get "http://#{host_name}:#{@port}"
            response.code == 200
          rescue Errno::ECONNRESET, Errno::ECONNREFUSED, RestClient::ServerBrokeConnection => e
            Runtime::Logger.debug(".NET SDK sample app is not yet available: #{e.inspect}")
            false
          end
        end
      end
    end
  end
end
