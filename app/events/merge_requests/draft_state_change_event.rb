# frozen_string_literal: true

module MergeRequests
  class DraftStateChangeEvent < Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'required' => %w[
          current_user_id
          merge_request_id
        ],
        'properties' => {
          'current_user_id' => { 'type' => 'integer' },
          'merge_request_id' => { 'type' => 'integer' },
          # This field is optional and to be made required
          # in this follow up 19.2 Issue
          # https://gitlab.com/gitlab-org/gitlab/-/work_items/599148
          'new_draft_status' => { 'type' => 'boolean' }
        }
      }
    end
  end
end
