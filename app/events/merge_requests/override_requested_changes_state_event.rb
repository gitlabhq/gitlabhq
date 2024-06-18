# frozen_string_literal: true

module MergeRequests
  class OverrideRequestedChangesStateEvent < Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'required' => %w[
          current_user_id
          merge_request_id
        ],
        'properties' => {
          'current_user_id' => { 'type' => 'integer' },
          'merge_request_id' => { 'type' => 'integer' }
        }
      }
    end
  end
end
