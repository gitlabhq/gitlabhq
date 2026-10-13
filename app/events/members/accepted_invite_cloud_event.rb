# frozen_string_literal: true

module Members
  class AcceptedInviteCloudEvent < BaseEvent
    event_type :accepted_invite

    class << self
      def build(source:, current_user:, user_id:, member_id:)
        build_for_member_source(
          source: source,
          current_user: current_user,
          extra_event_data: { user_id: user_id, member_id: member_id }
        )
      end
    end

    private

    def additional_properties
      {
        'user_id' => { 'type' => 'integer' },
        'member_id' => { 'type' => 'integer' }
      }
    end

    def additional_required
      %w[user_id member_id]
    end
  end
end
