# frozen_string_literal: true

module MergeRequests
  class MergeableEvent < Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'required' => %w[
          merge_request_id
        ],
        'properties' => {
          'merge_request_id' => { 'type' => 'integer' }
        }
      }
    end
  end
end
