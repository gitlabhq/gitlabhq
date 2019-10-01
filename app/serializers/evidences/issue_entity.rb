# frozen_string_literal: true

module Evidences
  class IssueEntity < Grape::Entity
    expose :id
    expose :title
    expose :description
    expose :author, using: AuthorEntity
    expose :state
    expose :iid
    expose :confidential
    expose :created_at
    expose :due_date
  end
end
