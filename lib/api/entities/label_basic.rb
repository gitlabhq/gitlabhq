# frozen_string_literal: true

module API
  module Entities
    class LabelBasic < Grape::Entity
      expose :id, :name, :description, :description_html, :text_color

      expose :color do |label, options|
        label.color.to_s
      end
    end
  end
end
