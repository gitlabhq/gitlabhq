# frozen_string_literal: true

module API
  module Entities
    class ProjectLabel < Entities::Label
      expose :priority do |label, options|
        label.priority(options[:parent])
      end
      expose :is_project_label do |label, options|
        label.is_a?(::ProjectLabel)
      end
    end
  end
end
