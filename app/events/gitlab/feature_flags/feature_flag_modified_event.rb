# frozen_string_literal: true

module Gitlab
  module FeatureFlags
    class FeatureFlagModifiedEvent < ::Gitlab::EventStore::Event
      def schema
        {
          'type' => 'object',
          'properties' => {
            'feature_key' => { 'type' => 'string' },
            'operation' => { 'type' => 'string' },
            'actor' => {
              'type' => %w[string null]
            },
            'state' => { 'type' => 'string' }
          },
          'required' => %w[feature_key operation state]
        }
      end
    end
  end
end
