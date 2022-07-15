# frozen_string_literal: true

module Projects
  class ProjectPathChangedEvent < ::Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'properties' => {
          'project_id' => { 'type' => 'integer' },
          'namespace_id' => { 'type' => 'integer' },
          'root_namespace_id' => { 'type' => 'integer' },
          'old_path' => { 'type' => 'string' },
          'new_path' => { 'type' => 'string' }
        },
        'required' => %w[project_id namespace_id root_namespace_id old_path new_path]
      }
    end
  end
end
