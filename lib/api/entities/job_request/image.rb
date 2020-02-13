# frozen_string_literal: true

module API
  module Entities
    module JobRequest
      class Image < Grape::Entity
        expose :name, :entrypoint
        expose :ports, using: Entities::JobRequest::Port
      end
    end
  end
end
