# frozen_string_literal: true

module API
  module Entities
    class LabelBasic < Grape::Entity
      expose :id, :name, :color, :description, :description_html, :text_color, :remove_on_close
    end
  end
end
