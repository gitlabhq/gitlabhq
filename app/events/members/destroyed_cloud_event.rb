# frozen_string_literal: true

module Members
  class DestroyedCloudEvent < BaseEvent
    event_type :destroyed

    class << self
      # `root_namespace_id` is passed in rather than derived from `source` so
      # callers that already resolved the root ancestor do not query for it again.
      #
      # `current_user` may be nil for system flows with no acting user (for
      # example RemoveExpiredMembersWorker); CloudEvents support a nil actor, so
      # we pass it through rather than misattributing the action to a bot.
      def build(source:, current_user:, user_id:, root_namespace_id:)
        build_for_member_source(
          source: source,
          current_user: current_user,
          extra_event_data: {
            root_namespace_id: root_namespace_id,
            user_id: user_id
          }
        )
      end
    end

    private

    def additional_properties
      {
        'root_namespace_id' => { 'type' => 'integer' },
        'user_id' => { 'type' => %w[integer null] }
      }
    end

    # `root_namespace_id` stays optional, mirroring the legacy Members::DestroyedEvent
    # schema, while `user_id` must be present even though it may be null.
    def additional_required
      %w[user_id]
    end
  end
end
