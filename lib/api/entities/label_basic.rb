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

      expose :archived
    end
  end
end
