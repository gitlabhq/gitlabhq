# frozen_string_literal: true

module Members
  # TODO: Remove this legacy event in 19.6 once in-flight events have drained.
  # Dual-published alongside Members::DestroyedCloudEvent from Members::DestroyService
  # during the transition. See https://gitlab.com/gitlab-org/gitlab/-/work_items/606864
  class DestroyedEvent < ::Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'required' => %w[source_id source_type user_id],
        'properties' => {
          'root_namespace_id' => { 'type' => 'integer' },
          'source_id' => { 'type' => 'integer' },
          'source_type' => { 'type' => 'string' },
          'user_id' => { 'type' => %w[integer null] }
        }
      }
    end
  end
end
