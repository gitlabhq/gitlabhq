# frozen_string_literal: true

module API
  module Entities
    class LabelBasic < Grape::Entity
      expose :id, :name, :description, :text_color

      expose :description_html do |label|
        MarkupHelper.markdown_field(label, :description, current_user: options[:current_user])
      end

      expose :color do |label, options|
        label.color.to_s
      end

      expose :archived, if: ->(label) {
        container = label.try(:preloaded_parent_container)

        group = case container
                when ::Group
                  container
                when ::Project
                  container.group
                end

        ::Feature.enabled?(:labels_archive, group)
      }
    end
  end
end
