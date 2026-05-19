# frozen_string_literal: true

module API
  module Entities
    class ProjectLabel < Entities::Label
      expose :priority, documentation: { type: 'Integer', example: 10 } do |label, options|
        label.priority(options[:parent])
      end
      expose :is_project_label, documentation: { type: 'Boolean' } do |label, options|
        label.is_a?(::ProjectLabel)
      end
    end
  end
end
