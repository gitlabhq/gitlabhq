# frozen_string_literal: true

module GitlabSubscriptions
  class RenewedCloudEvent < ::Gitlab::EventStore::CloudEvent
    event_category :gitlab_subscriptions
    event_type :renewed

    class << self
      def build(subscription:)
        build_cloud_event(
          source: "namespaces/#{subscription.namespace_id}",
          subject: "gitlab_subscriptions/#{subscription.id}",
          event_data: { namespace_id: subscription.namespace_id }
        )
      end
    end

    def data_schema
      {
        'type' => 'object',
        'required' => %w[namespace_id],
        'properties' => {
          'namespace_id' => { 'type' => 'integer' }
        },
        'additionalProperties' => false
      }
    end
  end
end
