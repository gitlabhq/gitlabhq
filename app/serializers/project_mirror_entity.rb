# frozen_string_literal: true

class ProjectMirrorEntity < Grape::Entity
  prepend ::EE::ProjectMirrorEntity # rubocop: disable Cop/InjectEnterpriseEditionModule

  expose :id

  expose :remote_mirrors_attributes, using: RemoteMirrorEntity do |project|
    project.remote_mirrors
  end
end
