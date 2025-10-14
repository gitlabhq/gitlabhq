# frozen_string_literal: true

module Ci
  module Workloads
    class WorkloadFinishedEvent < ::Gitlab::EventStore::Event
      def schema
        {
          'type' => 'object',
          'required' => %w[workload_id status],
          'properties' => {
            'workload_id' => { 'type' => 'integer' },
            'status' => { 'type' => 'string' }
          }
        }
      end
    end
  end
end
