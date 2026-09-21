# frozen_string_literal: true

module Members
  class AcceptedInviteEvent < ::Gitlab::EventStore::Event
    # TODO: Remove in a later milestone after CloudEvent migration is complete.
    # Dual-published alongside AcceptedInviteCloudEvent in
    # gitlab/app/services/members/accept_invite_service.rb
    # to allow in-flight events to drain.
    # See https://gitlab.com/gitlab-org/gitlab/-/work_items/605291
    def schema
      {
        'type' => 'object',
        'required' => %w[source_id source_type user_id member_id],
        'properties' => {
          'member_id' => { 'type' => 'integer' },
          'source_id' => { 'type' => 'integer' },
          'source_type' => { 'type' => 'string' },
          'user_id' => { 'type' => 'integer' }
        }
      }
    end
  end
end
