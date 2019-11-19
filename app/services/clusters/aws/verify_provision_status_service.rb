# frozen_string_literal: true

module Clusters
  module Aws
    class VerifyProvisionStatusService
      attr_reader :provider

      INITIAL_INTERVAL = 5.minutes
      POLL_INTERVAL = 1.minute
      TIMEOUT = 30.minutes

      def execute(provider)
        @provider = provider

        case cluster_stack.stack_status
        when 'CREATE_IN_PROGRESS'
          continue_creation
        when 'CREATE_COMPLETE'
          finalize_creation
        else
          provider.make_errored!("Unexpected status; #{cluster_stack.stack_status}")
        end
      rescue ::Aws::CloudFormation::Errors::ServiceError => e
        provider.make_errored!("Amazon CloudFormation request failed; #{e.message}")
      end

      private

      def cluster_stack
        @cluster_stack ||= provider.api_client.describe_stacks(stack_name: provider.cluster.name).stacks.first
      end

      def continue_creation
        if timeout_threshold.future?
          WaitForClusterCreationWorker.perform_in(POLL_INTERVAL, provider.cluster_id)
        else
          provider.make_errored!(_('Kubernetes cluster creation time exceeds timeout; %{timeout}') % { timeout: TIMEOUT })
        end
      end

      def timeout_threshold
        cluster_stack.creation_time + TIMEOUT
      end

      def finalize_creation
        Clusters::Aws::FinalizeCreationService.new.execute(provider)
      end
    end
  end
end
