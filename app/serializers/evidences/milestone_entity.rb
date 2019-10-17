# frozen_string_literal: true

module Evidences
  class MilestoneEntity < Grape::Entity
    expose :id
    expose :title
    expose :description
    expose :state
    expose :iid
    expose :created_at
    expose :due_date
    expose :issues, using: Evidences::IssueEntity
  end
end
