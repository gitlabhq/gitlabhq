# frozen_string_literal: true

module MergeRequests
  class MergeRequestPreparedEvent < Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'required' => %w[project_id user_id oldrev newrev ref],
        'properties' => {
          'project_id' => { 'type' => 'integer' },
          'user_id' => { 'type' => 'integer' },
          'oldrev' => { 'type' => 'string' },
          'newrev' => { 'type' => 'string' },
          'ref' => { 'type' => 'string' }
        }
      }
    end
  end
end
