# frozen_string_literal: true

module Projects
  class ProjectFeaturesChangedEvent < ::Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'properties' => {
          'project_id' => { 'type' => 'integer' },
          'namespace_id' => { 'type' => 'integer' },
          'root_namespace_id' => { 'type' => 'integer' },
          'features' => { 'type' => 'array' }
        },
        'required' => %w[project_id namespace_id root_namespace_id features]
      }
    end

    def pages_related?
      data[:features].include?("pages_access_level")
    end
  end
end
