# frozen_string_literal: true

module API
  module Entities
    module Releases
      class Source < Grape::Entity
        expose :format, documentation: { type: 'string', example: 'zip' }
        expose :url, documentation: { type: 'string', example: 'https://gitlab.example.com/root/app/-/archive/v1.0/app-v1.0.zip' }
      end
    end
  end
end
