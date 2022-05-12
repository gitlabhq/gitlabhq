# frozen_string_literal: true

# TODO: consider removing this entity after https://gitlab.com/gitlab-org/gitlab/-/issues/360631
class ReleaseEntity < Grape::Entity
  expose :id
  expose :tag # see https://gitlab.com/gitlab-org/gitlab/-/issues/36338
  expose :name
  expose :description
  expose :project_id
  expose :author_id

  expose :created_at
  expose :updated_at
  expose :released_at
end
