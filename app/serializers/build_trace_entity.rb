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

  expose :json_lines, as: :lines, if: ->(*) { object.json? }
  expose :html_lines, as: :html, if: ->(*) { object.html? }
end
