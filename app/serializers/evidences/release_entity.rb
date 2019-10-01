# frozen_string_literal: true

module Evidences
  class ReleaseEntity < Grape::Entity
    expose :id
    expose :tag, as: :tag_name
    expose :name
    expose :description
    expose :created_at
    expose :project, using: ProjectEntity
    expose :milestones, using: MilestoneEntity
  end
end
