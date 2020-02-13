# frozen_string_literal: true

module API
  module Entities
    module Releases
      class Link < Grape::Entity
        expose :id
        expose :name
        expose :url
        expose :external?, as: :external
      end
    end
  end
end
