# frozen_string_literal: true

module ActivityPub
  class ReleasesActorEntity < Grape::Entity
    include RequestAwareEntity

    expose :id do |project|
      project_releases_url(project)
    end

    expose :type do |*|
      "Application"
    end

    expose :path, as: :preferredUsername do |project|
      "#{project.path}-releases"
    end

    expose :name do |project|
      "#{_('Releases')} - #{project.name}"
    end

    expose :description, as: :content

    expose nil, using: ProjectEntity, as: :context do |project|
      project
    end
  end
end
