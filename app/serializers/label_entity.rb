# frozen_string_literal: true

class LabelEntity < Grape::Entity
  expose :id

  expose :title
  expose :color do |label|
    label.color.to_s
  end
  expose :description
  expose :group_id
  expose :project_id
  expose :template
  expose :text_color
  expose :created_at
  expose :updated_at

  expose :priority, if: -> (*) { options.key?(:project) } do |label|
    label.priority(options[:project])
  end
end
