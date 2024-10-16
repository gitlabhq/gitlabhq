# frozen_string_literal: true

class LabelEntity < Issuables::BaseLabelEntity
  expose :group_id
  expose :project_id
  expose :template

  expose :priority, if: ->(*) { options.key?(:project) } do |label|
    label.priority(options[:project])
  end
end
