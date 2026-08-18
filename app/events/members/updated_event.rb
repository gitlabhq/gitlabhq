# frozen_string_literal: true

module Members
  class UpdatedEvent < ::Gitlab::EventStore::Event
    # TODO: Remove in milestone 19.4 after CloudEvent migration is complete.
    # Dual-published alongside UpdatedCloudEvent in gitlab/app/services/members/update_service.rb
    # To allow in-flight events to drain.
    # See https://gitlab.com/gitlab-org/gitlab/-/work_items/605666
    def schema
      {
        'type' => 'object',
        'required' => %w[source_id source_type user_ids],
        'properties' => {
          'source_id' => { 'type' => 'integer' },
          'source_type' => { 'type' => 'string' },
          'user_ids' => {
            'type' => 'array',
            'items' => { 'type' => 'integer' }
          }
        }
      }
    end
  end
end
