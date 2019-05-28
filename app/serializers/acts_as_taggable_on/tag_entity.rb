# frozen_string_literal: true

class ActsAsTaggableOn::TagEntity < Grape::Entity
  expose :id
  expose :name
end
