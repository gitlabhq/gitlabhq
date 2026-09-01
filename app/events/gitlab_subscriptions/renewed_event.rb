# frozen_string_literal: true

module GitlabSubscriptions
  # TODO: Remove once RenewedCloudEvent is published and in-flight events have drained.
  # See https://gitlab.com/gitlab-org/gitlab/-/work_items/605296
  class RenewedEvent < Gitlab::EventStore::Event
    # Uniform reader so subscribers consume this and RenewedCloudEvent identically.
    alias_method :event_data, :data

    def schema
      {
        'type' => 'object',
        'required' => %w[
          namespace_id
        ],
        'properties' => {
          'namespace_id' => { 'type' => 'integer' }
        }
      }
    end
  end
end
