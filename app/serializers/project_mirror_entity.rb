# frozen_string_literal: true

class ProjectMirrorEntity < Grape::Entity
  prepend ::EE::ProjectMirrorEntity

  expose :id

  expose :remote_mirrors_attributes do |project|
    next [] unless project.remote_mirrors.present?

    project.remote_mirrors.map do |remote|
      remote.as_json(only: %i[id url enabled])
    end
  end
end
