# frozen_string_literal: true

module API
  module Entities
    class NpmPackage < Grape::Entity
      expose :name
      expose :versions
      expose :dist_tags, as: 'dist-tags'
    end
  end
end
