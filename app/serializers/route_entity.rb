# frozen_string_literal: true

class RouteEntity < Grape::Entity
  expose :id
  expose :source_id
  expose :source_type
  expose :path
end
