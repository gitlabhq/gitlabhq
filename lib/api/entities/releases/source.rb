# frozen_string_literal: true

module API
  module Entities
    module Releases
      class Source < Grape::Entity
        expose :format
        expose :url
      end
    end
  end
end
