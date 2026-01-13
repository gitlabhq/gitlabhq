# frozen_string_literal: true

module API
  module Entities
    class X509Certificate < Grape::Entity
      expose :id, documentation: { type: 'Integer', example: 1 }
      expose :subject, documentation: { type: 'String', example: 'CN=gitlab@example.org,OU=Example,O=World' }
      expose :subject_key_identifier, documentation: {
        type: 'String',
        example: 'BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC'
      }
      expose :email, documentation: { type: 'String', example: 'gitlab@example.org' }
      expose :serial_number, documentation: { type: 'Integer', example: 278969561018901340486471282831158785578 }
      expose :certificate_status, documentation: { type: 'String', example: 'good' }
      expose :x509_issuer, using: ::API::Entities::X509Issuer, documentation: { type: 'string', example: '100755' }
    end
  end
end
