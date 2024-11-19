# frozen_string_literal: true

module Issuables
  class BaseLabelEntity < Grape::Entity
    expose :id

    expose :title
    expose :color do |label|
      label.color.to_s
    end
    expose :description
    expose :text_color
    expose :created_at
    expose :updated_at
  end
end
