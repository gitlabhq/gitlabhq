# frozen_string_literal: true

module Integrations
  class ProjectEntity < Grape::Entity
    include RequestAwareEntity

    expose :id
    expose :avatar_url
    expose :full_name
    expose :name

    expose :full_path do |project|
      project_path(project)
    end
  end
end
