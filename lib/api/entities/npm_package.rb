# frozen_string_literal: true

module API
  module Entities
    class NpmPackage < Grape::Entity
      expose :name, documentation: { type: 'string', example: 'my_package' }
      expose :versions,
        documentation: {
          type: 'object',
          example: '{
                 "1.0.0": {
                   "name": "my_package",
                   "version": "1.0.0",
                   "dist": { "shasum": "12345", "tarball": "https://..." }
                 }
               }'
        }
      expose :dist_tags, as: 'dist-tags', documentation: { type: 'object', example: '{ "latest":"1.0.1" }' }
    end
  end
end
