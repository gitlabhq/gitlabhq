# frozen_string_literal: true

module Members
  class MembersAddedEvent < ::Gitlab::EventStore::Event
    # TODO: Remove in milestone 19.5. Members::AddedCloudEvent replaces this event,
    # but its subscribers must ship before the publisher switches to it in 19.4,
    # and this event must stay registered for one more milestone so in-flight
    # legacy events can drain.
    # See https://gitlab.com/gitlab-org/gitlab/-/work_items/605291
    def schema
      {
        'type' => 'object',
        'required' => %w[source_id source_type],
        'properties' => {
          'source_id' => { 'type' => 'integer' },
          'source_type' => { 'type' => 'string' },
          'invited_user_ids' => {
            'type' => 'array',
            'items' => { 'type' => 'integer' }
          }
        }
      }
    end
  end
end
