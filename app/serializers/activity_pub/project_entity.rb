# frozen_string_literal: true

module ActivityPub
  class ProjectEntity < Grape::Entity
    include RequestAwareEntity

    expose :id do |project|
      project_url(project)
    end

    expose :type do |*|
      "Application"
    end

    expose :name

    expose :description, as: :summary

    expose :url do |project|
      project_url(project)
    end
  end
end
