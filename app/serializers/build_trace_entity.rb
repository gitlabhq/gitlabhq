# frozen_string_literal: true

class BuildTraceEntity < Grape::Entity
  expose :build_id, as: :id
  expose :build_status, as: :status
  expose :build_complete?, as: :complete

  expose :state
  expose :append
  expose :truncated
  expose :offset
  expose :size
  expose :total

  expose :lines
end
