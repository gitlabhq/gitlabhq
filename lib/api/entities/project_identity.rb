# frozen_string_literal: true

module API
  module Entities
    class ProjectIdentity < Grape::Entity
      expose :id, :description
      expose :name, :name_with_namespace
      expose :path, :path_with_namespace
      expose :created_at
    end
  end
end
