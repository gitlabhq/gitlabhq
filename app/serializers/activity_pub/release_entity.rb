# frozen_string_literal: true

module ActivityPub
  class ReleaseEntity < Grape::Entity
    include RequestAwareEntity

    expose :id do |release, opts|
      "#{opts[:url]}##{release.tag}"
    end

    expose :type do |*|
      "Create"
    end

    expose :to do |*|
      'https://www.w3.org/ns/activitystreams#Public'
    end

    expose :author, as: :actor, using: UserEntity

    expose :object do
      expose :id do |release|
        project_release_url(release.project, release)
      end

      expose :type do |*|
        "Application"
      end

      expose :name

      expose :url do |release|
        project_release_url(release.project, release)
      end

      expose :description, as: :content
      expose :project, as: :context, using: ProjectEntity
    end
  end
end
