# frozen_string_literal: true

module Projects
  class ProjectTransferedEvent < ::Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'properties' => {
          'project_id' => { 'type' => 'integer' },
          'old_namespace_id' => { 'type' => 'integer' },
          'old_root_namespace_id' => { 'type' => 'integer' },
          'new_namespace_id' => { 'type' => 'integer' },
          'new_root_namespace_id' => { 'type' => 'integer' }
        },
        'required' => %w[
          project_id
          old_namespace_id
          old_root_namespace_id
          new_namespace_id
          new_root_namespace_id
        ]
      }
    end
  end
end
