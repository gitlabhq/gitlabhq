# frozen_string_literal: true

module API
  module Entities
    module Ci
      class SecureFile < Grape::Entity
        expose :id, documentation: { type: 'Integer', example: 123 }
        expose :name, documentation: { type: 'String', example: 'upload-keystore.jks' }
        expose :checksum,
          documentation: { type: 'String', example: '16630b189ab34b2e3504f4758e1054d2e478deda510b2b08cc0ef38d12e80aac' }
        expose :checksum_algorithm, documentation: { type: 'String', example: 'sha256' }
        expose :created_at, documentation: { type: 'DateTime', example: '2022-02-22T22:22:22.222Z' }
        expose :expires_at, documentation: { type: 'DateTime', example: '2023-09-21T14:55:59.000Z' }
        expose :metadata, documentation: { type: 'Hash', example: { "id" => "75949910542696343243264405377658443914" } }
        expose :file_extension, documentation: { type: 'String', example: 'jks' }
      end
    end
  end
end
