# frozen_string_literal: true

module Projects
  class ProjectVisibilityChangedEvent < ::Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'properties' => {
          'project_id' => { 'type' => 'integer' },
          'namespace_id' => { 'type' => 'integer' },
          'root_namespace_id' => { 'type' => 'integer' },
          'visibility_level' => { 'type' => 'integer' }
        },
        'required' => %w[project_id namespace_id root_namespace_id visibility_level]
      }
    end
  end
end
