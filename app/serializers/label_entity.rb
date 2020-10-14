# frozen_string_literal: true

class LabelEntity < Grape::Entity
  expose :id, if: ->(label, _) { !label.is_a?(GlobalLabel) }

  expose :title
  expose :color
  expose :description
  expose :group_id
  expose :project_id, if: ->(label, _) { !label.is_a?(GlobalLabel) }
  expose :template
  expose :text_color
  expose :created_at
  expose :updated_at

  expose :priority, if: -> (*) { options.key?(:project) } do |label|
    label.priority(options[:project])
  end
end
