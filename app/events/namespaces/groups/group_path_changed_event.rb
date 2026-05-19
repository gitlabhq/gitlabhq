# frozen_string_literal: true

module Namespaces
  module Groups
    class GroupPathChangedEvent < ::Gitlab::EventStore::Event
      def schema
        {
          'type' => 'object',
          'properties' => {
            'group_id' => { 'type' => 'integer' }
          },
          'required' => %w[group_id]
        }
      end
    end
  end
end
