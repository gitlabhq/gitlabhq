# frozen_string_literal: true

module API
  module Entities
    class Suggestion < Grape::Entity
      expose :id
      expose :from_line
      expose :to_line
      expose :appliable?, as: :appliable
      expose :applied
      expose :from_content
      expose :to_content
    end
  end
end
