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
          when 'PENDING', 'RUNNING'
            continue_creation(operation)
          when 'DONE'
            finalize_creation
          else
            provider.make_errored!("Unexpected operation status; #{operation.status} #{operation.status_message}")
          end
        end
      end

      private

      def continue_creation(operation)
        if elapsed_time_from_creation(operation) < TIMEOUT
          WaitForClusterCreationWorker.perform_in(EAGER_INTERVAL, provider.cluster_id)
        else
          provider.make_errored!(_('Kubernetes cluster creation time exceeds timeout; %{timeout}') % { timeout: TIMEOUT })
        end
      end

      def elapsed_time_from_creation(operation)
        Time.now.utc - operation.start_time.to_time.utc
      end

      def finalize_creation
        Clusters::Gcp::FinalizeCreationService.new.execute(provider)
      end

      def request_operation(&blk)
        Clusters::Gcp::FetchOperationService.new.execute(provider, &blk)
      end
    end
  end
end
