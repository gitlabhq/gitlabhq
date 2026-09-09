# frozen_string_literal: true

module Members
  class AddedCloudEvent < BaseEvent
    event_type :added

    class << self
      def build(source:, current_user:, invited_user_ids:)
        build_for_member_source(
          source: source,
          current_user: current_user,
          extra_event_data: { invited_user_ids: invited_user_ids }
        )
      end
    end

    private

    def additional_properties
      {
        'invited_user_ids' => {
          'type' => 'array',
          'items' => { 'type' => 'integer' }
        }
      }
    end

    def additional_required
      %w[invited_user_ids]
    end
  end
end
