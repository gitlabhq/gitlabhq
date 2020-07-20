# frozen_string_literal: true

module API
  module Entities
    class NpmPackageTag < Grape::Entity
      expose :dist_tags, merge: true
    end
  end
end
