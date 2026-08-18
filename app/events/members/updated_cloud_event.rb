# frozen_string_literal: true

module Members
  class UpdatedCloudEvent < BaseEvent
    event_type :updated

    class << self
      def build(source:, current_user:, user_ids:)
        build_for_member_source(
          source: source,
          current_user: current_user,
          extra_event_data: { user_ids: user_ids }
        )
      end
    end

    private

    def additional_properties
      {
        'user_ids' => {
          'type' => 'array',
          'items' => { 'type' => 'integer' }
        }
      }
    end

    def additional_required
      %w[user_ids]
    end
  end
end
