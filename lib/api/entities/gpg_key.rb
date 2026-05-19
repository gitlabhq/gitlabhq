# frozen_string_literal: true

module API
  module Entities
    class GpgKey < Grape::Entity
      expose :id, documentation: { type: 'Integer', example: 1 }
      expose :key, documentation: { type: 'String', example: '-----BEGIN PGP PUBLIC KEY BLOCK-----' }
      expose :created_at, documentation: { type: 'DateTime', example: '2017-09-05T09:17:46.264Z' }
    end
  end
end
