module Clusters
  module Gcp
    class VerifyProvisionStatusService
      attr_reader :provider

      INITIAL_INTERVAL = 2.minutes
      EAGER_INTERVAL = 10.seconds
      TIMEOUT = 20.minutes

      def execute(provider)
        @provider = provider

        request_operation do |operation|
          case operation.status
          when 'RUNNING'
            continue_creation(operation)
          when 'DONE'
            finalize_creation
          else
            return provider.make_errored!("Unexpected operation status; #{operation.status} #{operation.status_message}")
          end
        end
      end

      private

      def continue_creation(operation)
        if TIMEOUT < Time.now.utc - operation.start_time.to_time.utc
          return provider.make_errored!("Cluster creation time exceeds timeout; #{TIMEOUT}")
        end

        WaitForClusterCreationWorker.perform_in(EAGER_INTERVAL, provider.cluster_id)
      end

      def finalize_creation
        Clusters::Gcp::FinalizeCreationService.new.execute(provider)
      end

      def request_operation(&blk)
        Clusters::FetchGcpOperationService.new.execute(provider, &blk)
      end
    end
  end
end
