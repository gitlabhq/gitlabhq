# frozen_string_literal: true

module QA
  module Service
    module DockerRun
      module ProductAnalytics
        class RubySdkApp < Base
          include Support::API

          def initialize(sdk_host)
            # Below is an image of a sample app that uses Product Analytics ruby SDK.
            # The image is created in https://gitlab.com/gitlab-org/analytics-section/product-analytics/gl-application-sdk-rb
            # It's built on every merge to main branch in the repository.
            # @name should not contain _ (underscores) as it is used to generate host_name
            # and _ are not allowed for domain names.
            @image = 'registry.gitlab.com/gitlab-org/analytics-section/product-analytics/' \
              'gl-application-sdk-rb/example-app:main'
            @name = 'ruby-sdk'
            @sdk_host = URI(sdk_host)
            @port = '5172'
            @host_name = 'localhost' unless Runtime::Env.running_in_ci?

            super()
          end

          def register!(sdk_app_id)
            shell <<~CMD.tr("\n", ' ')
              docker run -d --rm
              --name #{@name}
              --network #{network}
              --hostname #{host_name}
              -p #{@port}:#{@port}
              -e PA_COLLECTOR_URL=#{@sdk_host}
              -e PA_APPLICATION_ID=#{sdk_app_id}
              #{@image}
              -p #{@port}
            CMD

            wait_for_app_available
          end

          def trigger_event
            get "http://#{host_name}:#{@port}/api/v1/send_event"
            Runtime::Logger.info('Ruby SDK event is triggered!')
          end

          private

          def wait_for_app_available
            Runtime::Logger.info("Waiting for Ruby SDK sample app to become available at http://#{host_name}:#{@port}...")
            Support::Waiter.wait_until(sleep_interval: 1,
              message: "Wait for Ruby SDK sample app to become available at http://#{host_name}:#{@port}") { app_available? }
            Runtime::Logger.info('Ruby SDK sample app is up!')
          end

          def app_available?
            response = get "http://#{host_name}:#{@port}"
            response.code == 200
          rescue Errno::ECONNRESET, Errno::ECONNREFUSED, RestClient::ServerBrokeConnection => e
            Runtime::Logger.debug("Ruby SDK sample app is not yet available: #{e.inspect}")
            false
          end
        end
      end
    end
  end
end
