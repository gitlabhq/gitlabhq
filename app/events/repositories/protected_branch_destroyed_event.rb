# frozen_string_literal: true

module Repositories
  class ProtectedBranchDestroyedEvent < ::Gitlab::EventStore::Event
    PARENT_TYPES = {
      group: 'group',
      project: 'project'
    }.freeze

    def schema
      {
        'type' => 'object',
        'properties' => {
          'parent_id' => { 'type' => 'integer' },
          'parent_type' => { 'type' => 'string', 'enum' => PARENT_TYPES.values }
        },
        'required' => %w[parent_id parent_type]
      }
    end
  end
end
