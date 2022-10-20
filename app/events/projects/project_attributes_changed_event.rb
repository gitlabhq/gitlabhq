# frozen_string_literal: true

module Projects
  class ProjectAttributesChangedEvent < ::Gitlab::EventStore::Event
    PAGES_RELATED_ATTRIBUTES = %w[
      pages_https_only
      visibility_level
    ].freeze

    def schema
      {
        'type' => 'object',
        'properties' => {
          'project_id' => { 'type' => 'integer' },
          'namespace_id' => { 'type' => 'integer' },
          'root_namespace_id' => { 'type' => 'integer' },
          'attributes' => { 'type' => 'array' }
        },
        'required' => %w[project_id namespace_id root_namespace_id attributes]
      }
    end

    def pages_related?
      PAGES_RELATED_ATTRIBUTES.any? do |attribute|
        data[:attributes].include?(attribute)
      end
    end
  end
end
