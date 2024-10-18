# frozen_string_literal: true

class ProjectEntity < Grape::Entity
  include RequestAwareEntity

  expose :id, documentation: { type: 'integer', example: 1 }
  expose :name, documentation: { type: 'string', example: 'GitLab' }

  expose :full_path, documentation: { type: 'string', example: 'gitlab-org/gitlab' } do |project|
    project_path(project)
  end

  expose :full_name, documentation: { type: 'string', example: 'GitLab Org / GitLab' } do |project|
    project.full_name
  end

  expose :refs_url do |project|
    refs_project_path(project)
  end

  expose :forked, documentation: { type: 'boolean', example: true } do |project|
    project.forked?
  end
end
