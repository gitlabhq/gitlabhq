# frozen_string_literal: true

module API
  module Entities
    class SshCertificate < Grape::Entity
      expose :id, documentation: { type: 'Integer', format: 'int64', example: 142 }
      expose :title, documentation: { type: 'String', example: 'new ssh cert' }
      expose :key, documentation: { type: 'String' }
      expose :created_at, documentation: { type: 'DateTime', example: "2022-01-31T15:10:45.080Z" }
    end
  end
end
