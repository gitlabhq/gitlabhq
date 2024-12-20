# frozen_string_literal: true

module Packages
  class PackageCreatedEvent < ::Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'properties' => {
          'project_id' => { 'type' => 'integer' },
          'name' => { 'type' => 'string' },
          'version' => { 'type' => %w[string null] },
          'package_type' => { 'type' => 'string', 'enum' => ::Packages::Package.package_types.keys },
          'id' => { 'type' => 'integer' }
        },
        'required' => %w[project_id id name package_type]
      }
    end

    def ml_model?
      data[:package_type] == 'ml_model'
    end
  end
end
