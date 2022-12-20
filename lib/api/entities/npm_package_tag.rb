# frozen_string_literal: true

module API
  module Entities
    class NpmPackageTag < Grape::Entity
      expose :dist_tags, merge: true, documentation: { type: 'object', example: '{ "latest":"1.0.1" }' }
    end
  end
end
